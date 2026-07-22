import os
import sys
import re
from datetime import datetime, date
from curl_cffi import requests as cffi_requests
import requests
from bs4 import BeautifulSoup

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.player import Player, TennisHistoricalPlayer, TennisHistoricalRanking

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

def scrape_atp_date(date_str):
    url = f"https://www.atptour.com/en/rankings/singles?dateWeek={date_str}"
    print(f"Scraping ATP rankings for {date_str}...")
    try:
        r = cffi_requests.get(url, impersonate="chrome120", timeout=15)
        if r.status_code != 200:
            print(f"  ATP {date_str} HTTP {r.status_code}")
            return []
        soup = BeautifulSoup(r.text, "html.parser")
        rows = soup.select("tr")
        parsed = []
        for row in rows:
            player_link = row.select_one(".name a") or row.select_one('a[href*="/players/"]')
            if not player_link:
                continue
            href = player_link.get("href", "")
            if "/players/" not in href:
                continue
            parts = href.split("/")
            idx = parts.index("players")
            slug = parts[idx + 1]
            name = " ".join(slug.split("-")).title()
            
            rank_cell = row.select_one("td.rank") or row.select_one(".rank-cell")
            rank = 0
            if rank_cell:
                rt = rank_cell.text.strip().replace("T", "")
                if rt.isdigit(): rank = int(rt)
                
            pts_cell = row.select_one("td.points") or row.select_one(".points-cell")
            pts = 0
            if pts_cell:
                pt = pts_cell.text.strip().replace(",", "")
                if pt.isdigit(): pts = int(pt)
                
            country = "Unknown"
            flag = row.select_one("use")
            if flag and flag.get("href"):
                cm = flag.get("href").split("#flag-")
                if len(cm) > 1: country = cm[1].upper()
                
            if name and rank > 0:
                parsed.append({"name": name, "rank": rank, "points": pts, "country": country})
        print(f"  Scraped {len(parsed)} ATP players for {date_str}")
        return parsed
    except Exception as e:
        print(f"  Error scraping ATP {date_str}: {e}")
        return []

def scrape_wta_date(date_str):
    url = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={date_str}&pageSize=100&page=0"
    headers = {"User-Agent": "Mozilla/5.0"}
    print(f"Scraping WTA rankings for {date_str}...")
    try:
        res = requests.get(url, headers=headers, timeout=15)
        if res.status_code != 200:
            print(f"  WTA {date_str} HTTP {res.status_code}")
            return []
        data = res.json()
        parsed = []
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
                parsed.append({"name": name, "rank": rank, "points": pts, "country": country, "wta_dob": dob})
        print(f"  Scraped {len(parsed)} WTA players for {date_str}")
        return parsed
    except Exception as e:
        print(f"  Error scraping WTA {date_str}: {e}")
        return []

def main():
    db = SessionLocal()

    print("Pre-loading historical and active players from DB...")
    players_hist = db.query(TennisHistoricalPlayer).all()
    player_hist_dict = {(p.first_name.lower(), p.last_name.lower(), p.gender): p for p in players_hist}

    active_players = db.query(Player).all()
    active_player_dict = {(p.name.lower(), p.gender): p for p in active_players}

    def resolve_player(first_name, last_name, gender, country, wta_dob, rank):
        key = (first_name.lower(), last_name.lower(), gender)
        full_name = f"{first_name} {last_name}"
        gender_str = "M" if gender == 0 else "F"
        active_key = (full_name.lower(), gender_str)

        # 1. Update/create in active players table
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

        # 2. Historical player lookup / create
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

    dates_to_process = ["2026-07-06", "2026-07-13", "2026-07-20"]
    total_added = 0

    try:
        for d_str in dates_to_process:
            d_obj = datetime.strptime(d_str, "%Y-%m-%d").date()
            year, month, day = d_obj.year, d_obj.month, d_obj.day

            atp_rows = scrape_atp_date(d_str)
            wta_rows = scrape_wta_date(d_str)

            if not atp_rows and not wta_rows:
                print(f"No rows for {d_str}, skipping.")
                continue

            existing_rk = db.query(TennisHistoricalRanking.player_id).filter_by(
                ranking_year=year, ranking_month=month, ranking_date=day
            ).all()
            existing_pids = {r[0] for r in existing_rk}

            new_rankings = []
            for r in atp_rows:
                fn, ln = clean_and_split_name(r["name"])
                if fn:
                    pid = resolve_player(fn, ln, 0, r["country"], None, r["rank"])
                    if pid not in existing_pids:
                        new_rankings.append({
                            'player_id': pid, 'points': r["points"], 'rank': r["rank"],
                            'ranking_date': day, 'ranking_month': month, 'ranking_year': year
                        })
                        existing_pids.add(pid)

            for r in wta_rows:
                fn, ln = clean_and_split_name(r["name"])
                if fn:
                    pid = resolve_player(fn, ln, 1, r["country"], r.get("wta_dob"), r["rank"])
                    if pid not in existing_pids:
                        new_rankings.append({
                            'player_id': pid, 'points': r["points"], 'rank': r["rank"],
                            'ranking_date': day, 'ranking_month': month, 'ranking_year': year
                        })
                        existing_pids.add(pid)

            if new_rankings:
                db.bulk_insert_mappings(TennisHistoricalRanking, new_rankings)
                db.commit()
                print(f"Saved {len(new_rankings)} new rankings for date {d_str} into database!")
                total_added += len(new_rankings)
            else:
                db.commit()
                print(f"All rankings for {d_str} already exist in database.")

        print(f"\n=========================================")
        print(f"Tennis Ranking Scrape Complete!")
        print(f"Total new historical rankings added: {total_added}")
        print(f"=========================================")

    except Exception as e:
        db.rollback()
        print(f"Error during scrape/import: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    main()
