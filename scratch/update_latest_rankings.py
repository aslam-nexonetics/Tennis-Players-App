import os
import sys
import re
import urllib.parse
import requests
from datetime import datetime, date

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

def scrape_tennis_for_date(db, target_date_str="2026-08-03"):
    print(f"\n--- Scraping Tennis Rankings for {target_date_str} ---")
    d_obj = datetime.strptime(target_date_str, "%Y-%m-%d").date()
    year, month, day = d_obj.year, d_obj.month, d_obj.day

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

    atp_rows = []
    try:
        from scraper.scrapers.atp_scraper import ATPScraper
        atp = ATPScraper()
        soup = atp.get_soup_playwright("https://www.atptour.com/en/rankings/singles?rankRange=1-100")
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

    print(f"Scraped {len(atp_rows)} ATP players for {target_date_str}")

    wta_rows = []
    url = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={target_date_str}&pageSize=100&page=0"
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

    print(f"Scraped {len(wta_rows)} WTA players for {target_date_str}")

    existing_rk = db.query(TennisHistoricalRanking.player_id).filter_by(
        ranking_year=year, ranking_month=month, ranking_date=day
    ).all()
    existing_pids = {r[0] for r in existing_rk}

    new_rankings = []
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
        print(f"✅ Successfully inserted {len(new_rankings)} tennis rankings for {target_date_str} into DB!")
    else:
        db.commit()
        print(f"No new tennis rankings inserted (already existed).")

def clean_tt_name(name_str):
    if not name_str: return ""
    name_str = name_str.replace('^^', ' ')
    return re.sub(r'\s+', ' ', name_str).strip()

def scrape_tt_for_date(db, target_date_str="2026-08-04"):
    print(f"\n--- Scraping Table Tennis Rankings for {target_date_str} ---")
    d_obj = datetime.strptime(target_date_str, "%Y-%m-%d").date()
    year, month, day = d_obj.year, d_obj.month, d_obj.day

    from scraper.scrapers.wtt_scraper import WTTScraper
    wtt = WTTScraper()

    all_hist_players = db.query(TableTennisHistoricalPlayer).all()
    fl_cache = {}
    lf_cache = {}
    token_cache = {}
    for p in all_hist_players:
        fl = f"{p.first_name or ''} {p.last_name or ''}".strip().lower()
        lf = f"{p.last_name or ''} {p.first_name or ''}".strip().lower()
        if fl: fl_cache[fl] = p.id
        if lf: lf_cache[lf] = p.id
        words = re.findall(r'\b[a-z]+\b', fl)
        if len(words) >= 2:
            token_cache.setdefault((p.gender, words[0], words[-1]), p.id)

    def resolve_tt_historical_player(name, country, gender_int):
        cleaned = clean_tt_name(name).lower()
        pid = fl_cache.get(cleaned) or lf_cache.get(cleaned)
        if pid: return pid
        
        words = re.findall(r'\b[a-z]+\b', cleaned)
        if len(words) >= 2:
            token_pid = token_cache.get((gender_int, words[0], words[-1]))
            if token_pid: return token_pid

        parts = clean_tt_name(name).split()
        fn = parts[0] if parts else clean_tt_name(name)
        ln = " ".join(parts[1:]) if len(parts) > 1 else ""
        new_p = TableTennisHistoricalPlayer(first_name=fn, last_name=ln, gender=gender_int, country=country)
        db.add(new_p)
        db.flush()
        fl_cache[cleaned] = new_p.id
        if len(words) >= 2:
            token_cache[(gender_int, words[0], words[-1])] = new_p.id
        return new_p.id

    all_act_players = db.query(TableTennisPlayer).all()
    act_cache = {p.name.lower(): p for p in all_act_players}

    categories = [("MEN'S SINGLES", "M", 0), ("WOMEN'S SINGLES", "F", 1)]
    rankings_to_add = []
    existing_rankings = db.query(TableTennisHistoricalRanking.player_id).filter_by(
        ranking_year=year, ranking_month=month, ranking_date=day
    ).all()
    existing_pids = {r[0] for r in existing_rankings}

    for tab_name, gender_code, gender_int in categories:
        encoded_tab = urllib.parse.quote(tab_name)
        url = f"https://www.worldtabletennis.com/allplayersranking?selectedTab={encoded_tab}&Age=SENIOR&Rank=1"
        soup = wtt.get_soup_playwright(url)
        if not soup:
            print(f"Failed to fetch TT {tab_name} page")
            continue
        rows = soup.select("tr.cursor_move") or soup.select("table tbody tr")
        print(f"Found {len(rows)} TT rows for {tab_name}")
        for row in rows:
            try:
                rank_cell = row.select_one(".player-rank") or row.select_one("td:nth-child(1)")
                name_cell = row.select_one(".player_name") or row.select_one("td:nth-child(2)")
                country_cell = row.select_one(".country_name") or row.select_one("td:nth-child(3)")
                pts_cell = row.select_one(".points") or row.select_one("td:nth-child(4)")
                if not rank_cell or not name_cell: continue
                r_txt = rank_cell.text.strip()
                if not r_txt.isdigit(): continue
                rank = int(r_txt)
                name = clean_tt_name(name_cell.text)
                country = country_cell.text.strip() if country_cell else "Unknown"
                pts = 0
                if pts_cell:
                    p_txt = pts_cell.text.strip().replace(",", "")
                    if p_txt.isdigit(): pts = int(p_txt)
                if name and rank > 0:
                    pid = resolve_tt_historical_player(name, country, gender_int)
                    if pid not in existing_pids:
                        rankings_to_add.append({
                            'player_id': pid, 'points': pts, 'rank': rank,
                            'ranking_date': day, 'ranking_month': month, 'ranking_year': year
                        })
                        existing_pids.add(pid)
                    act_p = act_cache.get(name.lower())
                    if act_p:
                        act_p.ranking = rank
                    else:
                        new_act = TableTennisPlayer(name=name, country=country, gender=gender_code, ranking=rank)
                        db.add(new_act)
                        db.flush()
                        act_cache[name.lower()] = new_act
            except Exception as ex:
                continue

    if rankings_to_add:
        db.bulk_insert_mappings(TableTennisHistoricalRanking, rankings_to_add)
        db.commit()
        print(f"✅ Successfully inserted {len(rankings_to_add)} TT rankings for {target_date_str} into DB!")
    else:
        db.commit()
        print(f"No new TT rankings inserted (already existed).")

if __name__ == "__main__":
    db = SessionLocal()
    try:
        scrape_tennis_for_date(db, "2026-08-03")
        scrape_tt_for_date(db, "2026-08-04")
    finally:
        db.close()
