#!/usr/bin/env python3
import os
import sys
import re
import requests
from datetime import datetime, date
from bs4 import BeautifulSoup

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from sqlalchemy import text
from app.db.session import SessionLocal
from app.models.player import Player, TennisHistoricalPlayer, TennisHistoricalRanking
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer, TableTennisHistoricalRanking

def clean_and_split_name(full_name: str):
    if not full_name:
        return "", ""
    name = " ".join(full_name.split()).strip()
    name = re.sub(r'\s+[A-Z]{3}$', '', name)
    parts = name.split()
    if len(parts) == 0:
        return "", ""
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], " ".join(parts[1:])

def parse_birth_date(birth_val):
    if not birth_val:
        return None, None, None
    if isinstance(birth_val, date):
        return birth_val.day, birth_val.month, birth_val.year
    if isinstance(birth_val, str):
        for fmt in ("%Y-%m-%d", "%B %d, %Y", "%d %b %Y"):
            try:
                d = datetime.strptime(birth_val.strip(), fmt).date()
                return d.day, d.month, d.year
            except ValueError:
                pass
    return None, None, None

def scrape_tennis_2026_07_27(db):
    print("\n==========================================")
    print("SCRAPING TENNIS RANKINGS (2026-07-27)...")
    print("==========================================")

    d_str = "2026-07-27"
    d_obj = datetime.strptime(d_str, "%Y-%m-%d").date()
    year, month, day = d_obj.year, d_obj.month, d_obj.day

    # Load cache
    players_hist = db.query(TennisHistoricalPlayer).all()
    player_hist_dict = {(p.first_name.lower(), p.last_name.lower(), p.gender): p for p in players_hist}

    active_players = db.query(Player).all()
    active_player_dict = {(p.name.lower(), p.gender): p for p in active_players}

    def resolve_tennis_player(first_name, last_name, gender, country, wta_dob, rank):
        key = (first_name.lower(), last_name.lower(), gender)
        full_name = f"{first_name} {last_name}"
        gender_str = "M" if gender == 0 else "F"
        active_key = (full_name.lower(), gender_str)

        act_p = active_player_dict.get(active_key)
        if act_p:
            if rank > 0:
                act_p.ranking = rank
        else:
            birth_day, birth_month, birth_year = parse_birth_date(wta_dob)
            dob_date = date(birth_year, birth_month, birth_day) if (birth_year and birth_month and birth_day) else None
            new_act = Player(
                name=full_name,
                gender=gender_str,
                country=country,
                birth_date=dob_date,
                source="atp" if gender == 0 else "wta",
                ranking=rank
            )
            db.add(new_act)
            db.flush()
            active_player_dict[active_key] = new_act

        hp = player_hist_dict.get(key)
        if hp:
            return hp.id

        birth_day, birth_month, birth_year = parse_birth_date(wta_dob)
        new_hp = TennisHistoricalPlayer(
            first_name=first_name,
            last_name=last_name,
            gender=gender,
            country=country,
            birth_date=birth_day,
            birth_month=birth_month,
            birth_year=birth_year
        )
        db.add(new_hp)
        db.flush()
        player_hist_dict[key] = new_hp
        return new_hp.id

    # Scrape ATP using ATPScraper (Playwright)
    atp_rows = []
    print(f"Scraping ATP rankings for {d_str}...")
    try:
        from scraper.scrapers.atp_scraper import ATPScraper
        atp = ATPScraper()
        soup = atp.get_soup_playwright(f"https://www.atptour.com/en/rankings/singles?rankRange=1-100")
        if soup:
            table = soup.select_one("table.rankings-table") or soup.select_one("table")
            if table:
                rows = table.select("tbody tr")
                for row in rows:
                    rank_cell = row.select_one("td.rank")
                    player_link = row.select_one(".name a")
                    if not rank_cell or not player_link: continue
                    rank_text = rank_cell.text.strip().replace("T", "")
                    if not rank_text.isdigit(): continue
                    ranking = int(rank_text)

                    player_url_path = player_link.get("href", "")
                    raw_name = player_link.text.strip()
                    name = " ".join(raw_name.split()).strip()
                    name = re.sub(r'\s+[A-Z]{3}$', '', name)

                    if "/players/" in player_url_path:
                        parts = player_url_path.split("/")
                        try:
                            slug = parts[parts.index("players") + 1]
                            name_from_slug = " ".join(slug.split("-")).title()
                            if "." in name or len(name) < len(name_from_slug):
                                name = name_from_slug
                        except (ValueError, IndexError):
                            pass

                    country = "Unknown"
                    flag_use = row.select_one("use")
                    if flag_use and flag_use.get("href"):
                        country_match = flag_use.get("href").split("#flag-")
                        if len(country_match) > 1: country = country_match[1].upper()

                    pts_cell = row.select_one("td.points") or row.select_one(".points-cell")
                    pts = 0
                    if pts_cell:
                        pt = pts_cell.text.strip().replace(",", "")
                        if pt.isdigit(): pts = int(pt)

                    if name and ranking > 0:
                        atp_rows.append({"name": name, "rank": ranking, "points": pts, "country": country})
    except Exception as e:
        print(f"Error scraping ATP: {e}")

    print(f"  Scraped {len(atp_rows)} ATP players.")

    # Scrape WTA
    wta_rows = []
    print(f"Scraping WTA rankings for {d_str}...")
    url = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={d_str}&pageSize=100&page=0"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        res = requests.get(url, headers=headers, timeout=15)
        if res.status_code == 200:
            data = res.json()
            for item in data:
                p_info = item.get("player", {})
                fn = p_info.get("firstName", "").strip()
                ln = p_info.get("lastName", "").strip()
                name = f"{fn} {ln}".strip()
                rank = item.get("ranking", 0)
                pts = item.get("points", 0)
                country = p_info.get("countryCode", "Unknown")
                dob = p_info.get("dateOfBirth")
                if name and rank:
                    wta_rows.append({"name": name, "rank": rank, "points": pts, "country": country, "wta_dob": dob})
    except Exception as e:
        print(f"Error scraping WTA: {e}")

    print(f"  Scraped {len(wta_rows)} WTA players.")

    # Insert into TennisHistoricalRanking
    existing_rk = db.query(TennisHistoricalRanking.player_id).filter_by(
        ranking_year=year, ranking_month=month, ranking_date=day
    ).all()
    existing_pids = {r[0] for r in existing_rk}

    new_rankings = []
    seen_ranks = set()

    for r in atp_rows:
        fn, ln = clean_and_split_name(r["name"])
        if fn:
            pid = resolve_tennis_player(fn, ln, 0, r["country"], None, r["rank"])
            if pid not in existing_pids:
                new_rankings.append({
                    'player_id': pid, 'points': r["points"], 'rank': r["rank"],
                    'ranking_date': day, 'ranking_month': month, 'ranking_year': year
                })
                existing_pids.add(pid)

    for r in wta_rows:
        fn, ln = clean_and_split_name(r["name"])
        if fn:
            pid = resolve_tennis_player(fn, ln, 1, r["country"], r.get("wta_dob"), r["rank"])
            if pid not in existing_pids:
                new_rankings.append({
                    'player_id': pid, 'points': r["points"], 'rank': r["rank"],
                    'ranking_date': day, 'ranking_month': month, 'ranking_year': year
                })
                existing_pids.add(pid)

    if new_rankings:
        db.bulk_insert_mappings(TennisHistoricalRanking, new_rankings)
        db.commit()
        print(f"✅ Saved {len(new_rankings)} new tennis rankings for {d_str}!")
    else:
        db.commit()
        print(f"All tennis rankings for {d_str} already up to date.")

def main():
    db = SessionLocal()
    try:
        scrape_tennis_2026_07_27(db)
    finally:
        db.close()

if __name__ == "__main__":
    main()
