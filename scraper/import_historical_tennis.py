import os
import sys
import re
import time
import argparse
from datetime import date, datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from dotenv import load_dotenv

# Set up project paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(script_dir)
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal, engine, Base
from app.models.player import Player, TennisHistoricalPlayer, TennisHistoricalRanking
from scrapers.wiki_scraper import WikiScraper
from utils.logger import log

# Ensure tables are created
Base.metadata.create_all(bind=engine)


def get_atp_dates():
    """Fetch the list of valid ATP ranking dates from the website dropdown."""
    log.info("Fetching valid ATP ranking dates from atptour.com...")
    from playwright.sync_api import sync_playwright
    from bs4 import BeautifulSoup

    url = "https://www.atptour.com/en/rankings/singles"
    dates = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
            page = context.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=60000)
            page.wait_for_selector("select#dateWeek-filter", state="attached", timeout=15000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            select = soup.find("select", id="dateWeek-filter")
            if select:
                for opt in select.find_all("option"):
                    val = opt.get("value")
                    if val and val != "Current Week" and re.match(r"^\d{4}-\d{2}-\d{2}$", val):
                        dates.append(val)
            browser.close()
    except Exception as e:
        log.error(f"Error fetching ATP dates: {e}")
        # Fallback to generating Mondays from 2020-01-01 to present
        log.info("Falling back to generating Mondays for dates...")
        start_date = date(2020, 1, 6)
        end_date = date.today()
        current = start_date
        while current <= end_date:
            dates.append(current.strftime("%Y-%m-%d"))
            current += timedelta(days=7)

    return sorted(list(set(dates)))


def parse_birth_date(birth_val):
    """Parses birth date string or date object into day, month, year."""
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


def clean_and_split_name(full_name: str):
    """Splits full name into first and last name."""
    if not full_name:
        return "", ""
    name = " ".join(full_name.split()).strip()
    name = re.sub(r'\s+[A-Z]{3}$', '', name)  # remove country suffix if present
    parts = name.split()
    if len(parts) == 0:
        return "", ""
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], " ".join(parts[1:])


def extract_name_from_slug(href: str):
    """Extracts first/last name from player URL slug."""
    if not href:
        return ""
    parts = href.split("/")
    if "players" in parts:
        try:
            idx = parts.index("players")
            slug = parts[idx + 1]
            return " ".join(slug.split("-")).title()
        except Exception:
            pass
    return ""


# Global player cache
player_cache = {}  # (first_name, last_name, gender) -> player_id
active_player_cache = set()  # (name.lower(), gender_str)


def load_player_cache(db):
    """Pre-loads existing historical players into memory cache."""
    log.info("Loading existing historical players into cache...")
    players = db.query(TennisHistoricalPlayer).all()
    for p in players:
        key = (p.first_name.lower(), p.last_name.lower(), p.gender)
        player_cache[key] = p.id
    log.info(f"Loaded {len(player_cache)} players into cache.")


def load_active_player_cache(db):
    """Pre-loads existing active players into memory cache."""
    log.info("Loading existing active players into cache...")
    players = db.query(Player.name, Player.gender).all()
    for name, gender in players:
        if name and gender:
            active_player_cache.add((name.lower(), gender))
    log.info(f"Loaded {len(active_player_cache)} active players into cache.")


def resolve_player(db, wiki, first_name, last_name, gender, country=None, wta_dob=None, rank=999):
    """Resolves player ID, searching cache, database, main players table, or Wikipedia."""
    key = (first_name.lower(), last_name.lower(), gender)
    full_name = f"{first_name} {last_name}"
    gender_str = "M" if gender == 0 else "F"
    
    active_key = (full_name.lower(), gender_str)
    birth_day, birth_month, birth_year = None, None, None
    picture = None
    prize_money = None
    p_country = country

    # 1. Ensure the player exists in the active players table
    if active_key not in active_player_cache:
        existing_p = db.query(Player).filter(
            Player.name.ilike(full_name),
            Player.gender == gender_str
        ).first()

        if existing_p:
            active_player_cache.add(active_key)
            birth_day, birth_month, birth_year = parse_birth_date(existing_p.birth_date)
            picture = existing_p.image_url
            prize_money = existing_p.prize_money
            if existing_p.country:
                p_country = existing_p.country
        else:
            # Player does not exist in the active players table. Resolve details and create it.
            if wta_dob:
                birth_day, birth_month, birth_year = parse_birth_date(wta_dob)

            if not birth_year and rank <= 100:
                log.info(f"Enriching new top player from Wiki: {full_name}")
                try:
                    wiki_data = wiki.enrich_player(full_name)
                    if wiki_data:
                        if wiki_data.get("birth_date"):
                            birth_day, birth_month, birth_year = parse_birth_date(wiki_data.get("birth_date"))
                        if wiki_data.get("image_url"):
                            picture = wiki_data.get("image_url")
                        if wiki_data.get("country") and not p_country:
                            p_country = wiki_data.get("country")
                except Exception as e:
                    log.error(f"Wiki lookup failed for {full_name}: {e}")

            # Create in active players table
            dob_date = None
            if birth_year and birth_month and birth_day:
                try:
                    dob_date = date(birth_year, birth_month, birth_day)
                except ValueError:
                    pass

            new_active_player = Player(
                name=full_name,
                gender=gender_str,
                country=p_country,
                birth_date=dob_date,
                image_url=picture,
                prize_money=prize_money,
                source="atp" if gender == 0 else "wta",
                ranking=rank
            )
            db.add(new_active_player)
            db.flush()
            active_player_cache.add(active_key)
            log.info(f"Created new active Player: {full_name} (ID: {new_active_player.id}) in 'players' table")

    # 2. Resolve historical player
    if key in player_cache:
        return player_cache[key]

    # Look up in DB historical table
    db_player = db.query(TennisHistoricalPlayer).filter(
        TennisHistoricalPlayer.first_name.ilike(first_name),
        TennisHistoricalPlayer.last_name.ilike(last_name),
        TennisHistoricalPlayer.gender == gender
    ).first()

    if db_player:
        player_cache[key] = db_player.id
        return db_player.id

    # If they are not in the historical table, retrieve active player info if not already resolved
    if birth_year is None:
        existing_p = db.query(Player).filter(
            Player.name.ilike(full_name),
            Player.gender == gender_str
        ).first()
        if existing_p:
            birth_day, birth_month, birth_year = parse_birth_date(existing_p.birth_date)
            picture = existing_p.image_url
            prize_money = existing_p.prize_money
            if existing_p.country:
                p_country = existing_p.country

    new_p = TennisHistoricalPlayer(
        first_name=first_name,
        last_name=last_name,
        gender=gender,
        country=p_country,
        birth_date=birth_day,
        birth_month=birth_month,
        birth_year=birth_year,
        picture=picture,
        prize_money=prize_money
    )
    db.add(new_p)
    db.flush()
    player_cache[key] = new_p.id
    log.info(f"Created new TennisHistoricalPlayer: {full_name} (ID: {new_p.id})")
    return new_p.id


def scrape_atp_date(date_str, limit_rank):
    """Scrapes ATP rankings for a specific date using Playwright."""
    from playwright.sync_api import sync_playwright
    from bs4 import BeautifulSoup

    url = f"https://www.atptour.com/en/rankings/singles?dateWeek={date_str}&rankRange=0-{limit_rank}"
    log.info(f"Scraping ATP rankings for {date_str}...")
    
    scraped_rows = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
            page = context.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=60000)
            page.wait_for_selector("table", state="attached", timeout=15000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            table = soup.select_one("table")
            if table:
                rows = table.select("tbody tr")
                for row in rows:
                    rank_cell = row.select_one("td.rank")
                    if not rank_cell:
                        continue
                    rank_text = rank_cell.text.strip().replace("T", "")
                    if not rank_text.isdigit():
                        continue
                    rank = int(rank_text)

                    player_link = row.select_one(".name a")
                    if not player_link:
                        continue
                    href = player_link.get("href", "")
                    name = extract_name_from_slug(href)
                    if not name:
                        name = player_link.text.strip()
                    
                    points_cell = row.select_one("td.points")
                    points = 0
                    if points_cell:
                        points_text = points_cell.text.strip().replace(",", "")
                        if points_text.isdigit():
                            points = int(points_text)

                    country = "Unknown"
                    flag_use = row.select_one("use")
                    if flag_use and flag_use.get("href"):
                        country_match = flag_use.get("href").split("#flag-")
                        if len(country_match) > 1:
                            country = country_match[1].upper()

                    scraped_rows.append({
                        "name": name,
                        "rank": rank,
                        "points": points,
                        "country": country
                    })
            browser.close()
    except Exception as e:
        log.error(f"Failed to scrape ATP date {date_str}: {e}")
    
    return scraped_rows


def scrape_wta_date(date_str, limit_rank):
    """Scrapes WTA rankings for a specific date using their JSON API."""
    import requests
    url = "https://api.wtatennis.com/tennis/players/ranked"
    params = {
        "metric": "SINGLES",
        "type": "rankSingles",
        "sort": "asc",
        "at": date_str,
        "pageSize": limit_rank,
        "page": 0
    }
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    scraped_rows = []
    log.info(f"Scraping WTA rankings for {date_str}...")
    try:
        response = requests.get(url, params=params, headers=headers, timeout=15)
        if response.status_code == 200:
            data = response.json()
            for item in data:
                player_info = item.get('player', {})
                first_name = player_info.get('firstName', '').strip()
                last_name = player_info.get('lastName', '').strip()
                name = f"{first_name} {last_name}".strip()
                rank = item.get('ranking')
                points = item.get('points', 0)
                country = player_info.get('countryCode', 'Unknown')
                dob = player_info.get('dateOfBirth')

                if name and rank:
                    scraped_rows.append({
                        "name": name,
                        "rank": rank,
                        "points": points,
                        "country": country,
                        "wta_dob": dob
                    })
        else:
            log.error(f"WTA API returned status code {response.status_code} for {date_str}")
    except Exception as e:
        log.error(f"Failed to scrape WTA date {date_str}: {e}")

    return scraped_rows


def scrape_date_data(date_str, gender, limit_rank):
    """Scrapes ATP/WTA ranking lists for a date week in parallel."""
    atp_rows = []
    wta_rows = []

    if gender in ("both", "male"):
        atp_rows = scrape_atp_date(date_str, limit_rank)
    if gender in ("both", "female"):
        wta_rows = scrape_wta_date(date_str, limit_rank)

    return date_str, atp_rows, wta_rows


def main():
    parser = argparse.ArgumentParser(description="Tennis Historical Rankings Importer")
    parser.add_argument("--start-year", type=int, default=2020, help="Start year (default: 2020)")
    parser.add_argument("--end-year", type=int, default=2026, help="End year (default: 2026)")
    parser.add_argument("--limit-rank", type=int, default=100, help="Rank limit per week (default: 100)")
    parser.add_argument("--frequency", choices=["weekly", "biweekly", "monthly"], default="weekly", help="Frequency of rankings (default: weekly)")
    parser.add_argument("--gender", choices=["both", "male", "female"], default="both", help="Gender to scrape (default: both)")
    parser.add_argument("--workers", type=int, default=4, help="Number of parallel scraping threads (default: 4)")
    
    args = parser.parse_args()

    # Get valid dates
    all_dates = get_atp_dates()
    
    # Filter by years
    filtered_dates = [d for d in all_dates if args.start_year <= int(d.split("-")[0]) <= args.end_year]
    log.info(f"Total valid dates from ATP dropdown in range {args.start_year}-{args.end_year}: {len(filtered_dates)}")

    # Apply frequency filtering
    if args.frequency == "biweekly":
        filtered_dates = filtered_dates[::2]
        log.info(f"Filtered to biweekly: {len(filtered_dates)} dates")
    elif args.frequency == "monthly":
        monthly_dates = {}
        for d in filtered_dates:
            key = d[:7]  # YYYY-MM
            if key not in monthly_dates:
                monthly_dates[key] = d
        filtered_dates = sorted(list(monthly_dates.values()))
        log.info(f"Filtered to monthly: {len(filtered_dates)} dates")

    if not filtered_dates:
        log.warning("No dates to process.")
        return

    # Start DB session and load player cache
    db = SessionLocal(expire_on_commit=False)
    wiki = WikiScraper()
    load_player_cache(db)
    load_active_player_cache(db)

    try:
        total_rankings = 0
        log.info(f"Starting parallel scraping with {args.workers} workers for {len(filtered_dates)} dates...")
        
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            # Submit all scraping tasks
            future_to_date = {
                executor.submit(scrape_date_data, d_str, args.gender, args.limit_rank): d_str
                for d_str in filtered_dates
            }
            
            # Retrieve results as they complete and insert into DB sequentially
            for i, future in enumerate(as_completed(future_to_date)):
                date_str = future_to_date[future]
                log.info(f"Processing scraped data for date {i+1}/{len(filtered_dates)}: {date_str}...")
                
                try:
                    _, atp_rows, wta_rows = future.result()
                    
                    d_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                    year, month, day = d_obj.year, d_obj.month, d_obj.day

                    records_to_process = []
                    for r in atp_rows:
                        fn, ln = clean_and_split_name(r["name"])
                        if fn:
                            records_to_process.append((fn, ln, 0, r["country"], r["points"], r["rank"], None))
                    for r in wta_rows:
                        fn, ln = clean_and_split_name(r["name"])
                        if fn:
                            records_to_process.append((fn, ln, 1, r["country"], r["points"], r["rank"], r.get("wta_dob")))

                    if not records_to_process:
                        log.info(f"No records found/scraped for date {date_str}")
                        continue

                    # Check which rankings already exist for this date
                    existing_rankings = db.query(TennisHistoricalRanking).filter_by(
                        ranking_year=year,
                        ranking_month=month,
                        ranking_date=day
                    ).all()
                    existing_player_ids = {rank.player_id for rank in existing_rankings}

                    rankings_to_insert = []
                    new_rankings_count = 0

                    for fn, ln, g_val, country, points, rank, dob in records_to_process:
                        try:
                            # resolve_player handles database cache lookup and fallback
                            player_id = resolve_player(db, wiki, fn, ln, g_val, country, dob, rank)
                            if player_id in existing_player_ids:
                                continue  # already has ranking for this date
                            
                            rankings_to_insert.append(
                                TennisHistoricalRanking(
                                    player_id=player_id,
                                    points=points,
                                    rank=rank,
                                    ranking_date=day,
                                    ranking_month=month,
                                    ranking_year=year
                                )
                            )
                            new_rankings_count += 1
                        except Exception as e:
                            log.error(f"Error processing record {(fn, ln)} on {date_str}: {e}")

                    if rankings_to_insert:
                        db.bulk_save_objects(rankings_to_insert)
                        db.commit()
                        log.info(f"Saved {new_rankings_count} rankings for {date_str}")
                        total_rankings += new_rankings_count
                    else:
                        db.commit()
                        log.info(f"All rankings for {date_str} already exist in database.")

                except Exception as e:
                    log.error(f"Error scraping or inserting date {date_str}: {e}")
            
        log.info(f"Historical import complete! Total rankings added: {total_rankings}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
