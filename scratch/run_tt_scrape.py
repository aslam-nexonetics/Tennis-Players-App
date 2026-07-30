#!/usr/bin/env python3
import os
import sys
import re
import urllib.parse
from datetime import datetime, date

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from sqlalchemy import text
from app.db.session import SessionLocal
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer, TableTennisHistoricalRanking

def clean_name(name_str):
    if not name_str:
        return ""
    name_str = re.sub(r'\s+', ' ', name_str)
    return name_str.strip()

def scrape_tt_rankings_for_date(db, target_date_str="2026-07-28"):
    print("\n==========================================")
    print(f"SCRAPING TABLE TENNIS RANKINGS ({target_date_str})...")
    print("==========================================")

    d_obj = datetime.strptime(target_date_str, "%Y-%m-%d").date()
    year, month, day = d_obj.year, d_obj.month, d_obj.day

    from scraper.scrapers.wtt_scraper import WTTScraper
    wtt = WTTScraper()

    # Pre-cache TableTennisHistoricalPlayer
    all_hist_players = db.query(TableTennisHistoricalPlayer).all()
    fl_cache = {}
    lf_cache = {}
    for p in all_hist_players:
        fl = f"{p.first_name or ''} {p.last_name or ''}".strip().lower()
        lf = f"{p.last_name or ''} {p.first_name or ''}".strip().lower()
        if fl: fl_cache[fl] = p.id
        if lf: lf_cache[lf] = p.id

    def resolve_tt_historical_player(name, country, gender_int):
        cleaned = clean_name(name).lower()
        pid = fl_cache.get(cleaned) or lf_cache.get(cleaned)
        if pid:
            return pid
        
        parts = clean_name(name).split()
        fn = parts[0] if parts else clean_name(name)
        ln = " ".join(parts[1:]) if len(parts) > 1 else ""

        new_p = TableTennisHistoricalPlayer(
            first_name=fn,
            last_name=ln,
            gender=gender_int,
            country=country
        )
        db.add(new_p)
        db.flush()
        fl_cache[cleaned] = new_p.id
        return new_p.id

    # Pre-cache TableTennisPlayer
    all_act_players = db.query(TableTennisPlayer).all()
    act_cache = {p.name.lower(): p for p in all_act_players}

    categories = [("MEN'S SINGLES", "M", 0), ("WOMEN'S SINGLES", "F", 1)]
    total_added = 0

    for tab_name, gender_code, gender_int in categories:
        print(f"\nScraping {tab_name}...")
        encoded_tab = urllib.parse.quote(tab_name)
        url = f"https://www.worldtabletennis.com/allplayersranking?selectedTab={encoded_tab}&Age=SENIOR&Rank=1"

        soup = wtt.get_soup_playwright(url)
        if not soup:
            print(f"Failed to fetch {tab_name} page.")
            continue

        rows = soup.select("tr.cursor_move") or soup.select("table tbody tr")
        print(f"  Found {len(rows)} table rows for {tab_name}")

        existing_rankings = db.query(TableTennisHistoricalRanking.player_id).filter_by(
            ranking_year=year, ranking_month=month, ranking_date=day
        ).all()
        existing_pids = {r[0] for r in existing_rankings}

        rankings_to_add = []
        parsed_count = 0

        for row in rows:
            try:
                rank_cell = row.select_one(".player-rank") or row.select_one("td:nth-child(1)")
                name_cell = row.select_one(".player_name") or row.select_one("td:nth-child(2)")
                country_cell = row.select_one(".country_name") or row.select_one("td:nth-child(3)")
                pts_cell = row.select_one(".points") or row.select_one("td:nth-child(4)")

                if not rank_cell or not name_cell:
                    continue

                for diff in rank_cell.select("app-rank-diff, .rank-diff"):
                    diff.decompose()

                rank_match = re.search(r"(\d+)", rank_cell.get_text(strip=True))
                if not rank_match: continue
                rank = int(rank_match.group(1))

                name = name_cell.get_text(strip=True)
                country = country_cell.get_text(strip=True) if country_cell else "Unknown"
                
                pts = 0
                if pts_cell:
                    pts_match = re.search(r"([\d,]+)", pts_cell.get_text(strip=True))
                    if pts_match: pts = int(pts_match.group(1).replace(",", ""))

                if not name or rank <= 0: continue
                parsed_count += 1

                # Update active player table
                act_p = act_cache.get(name.lower())
                if act_p:
                    act_p.ranking = rank
                else:
                    new_act = TableTennisPlayer(
                        name=name,
                        country=country,
                        ranking=rank,
                        gender=gender_code,
                        source="WTT Official"
                    )
                    db.add(new_act)
                    db.flush()
                    act_cache[name.lower()] = new_act

                # Resolve historical player
                pid = resolve_tt_historical_player(name, country, gender_int)
                if pid not in existing_pids:
                    rankings_to_add.append({
                        "player_id": pid,
                        "points": pts,
                        "rank": rank,
                        "ranking_year": year,
                        "ranking_month": month,
                        "ranking_date": day
                    })
                    existing_pids.add(pid)
            except Exception as e:
                print(f"Error parsing row: {e}")

        if rankings_to_add:
            db.bulk_insert_mappings(TableTennisHistoricalRanking, rankings_to_add)
            db.commit()
            print(f"✅ Saved {len(rankings_to_add)} historical TT rankings for {tab_name} ({target_date_str})!")
            total_added += len(rankings_to_add)
        else:
            db.commit()
            print(f"Parsed {parsed_count} rows for {tab_name}. Rankings already present or up to date.")

    print(f"\n==========================================")
    print(f"Table Tennis Scrape Complete! Total added: {total_added}")
    print(f"==========================================")

def main():
    db = SessionLocal()
    try:
        scrape_tt_rankings_for_date(db, "2026-07-28")
    finally:
        db.close()

if __name__ == "__main__":
    main()
