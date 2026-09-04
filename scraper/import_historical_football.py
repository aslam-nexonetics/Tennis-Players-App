import os
import sys
import re
import time
import requests
import json
from datetime import datetime
from bs4 import BeautifulSoup
from dotenv import load_dotenv

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(script_dir)
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal, engine, Base
from app.models.football_national_team import (
    FootballNationalTeam,
    FootballHistoricalTeam,
    FootballHistoricalRanking
)
from scraper.utils.logger import log

# Ensure tables are created
Base.metadata.create_all(bind=engine)

FIFA_API_BASE = "https://api.fifa.com/api/v3/fifarankings/rankings/rankingsbyschedule"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Origin": "https://www.fifa.com",
    "Referer": "https://www.fifa.com/"
}

# Country / Team Name Normalization map for consistency
NAME_MAPPINGS = {
    "USA": "United States",
    "IR Iran": "Iran",
    "Korea Republic": "South Korea",
    "Korea DPR": "North Korea",
    "Côte d'Ivoire": "Ivory Coast",
    "Cabo Verde": "Cape Verde",
    "Czechia": "Czech Republic",
    "St. Kitts and Nevis": "Saint Kitts and Nevis",
    "St. Vincent and the Grenadines": "Saint Vincent and the Grenadines",
    "St. Lucia": "Saint Lucia",
}

def clean_team_name(name: str) -> str:
    if not name:
        return ""
    cleaned = name.strip()
    return NAME_MAPPINGS.get(cleaned, cleaned)


def fetch_ranking_schedules(category: str):
    """
    Fetch all ranking schedule release dates for men or women from FIFA site NEXT_DATA script tag.
    Returns list of dicts: [{'id': ..., 'iso': ..., 'year': ..., 'month': ..., 'day': ...}]
    """
    url = f"https://inside.fifa.com/fifa-world-ranking/{category}"
    log.info(f"Extracting historical ranking schedules from {url}...")
    
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')
        script = soup.find('script', id='__NEXT_DATA__')
        if not script:
            log.error("Could not find __NEXT_DATA__ script tag on FIFA page.")
            return []
            
        data = json.loads(script.string)
        dates_by_year = data.get('props', {}).get('pageProps', {}).get('pageData', {}).get('ranking', {}).get('dates', [])
        
        schedules = []
        for year_entry in dates_by_year:
            for date_item in year_entry.get('dates', []):
                sid = date_item.get('id')
                iso_str = date_item.get('iso') or date_item.get('matchWindowEndDate')
                if not sid or not iso_str:
                    continue
                    
                # Parse date
                try:
                    dt = datetime.fromisoformat(iso_str.replace('Z', '+00:00'))
                except Exception:
                    # fallback format YYYY-MM-DD
                    dt = datetime.strptime(iso_str[:10], '%Y-%m-%d')
                    
                schedules.append({
                    'id': sid,
                    'iso': iso_str,
                    'year': dt.year,
                    'month': dt.month,
                    'day': dt.day,
                    'dt': dt
                })
                
        # Sort chronologically (oldest to newest)
        schedules.sort(key=lambda x: x['dt'])
        log.info(f"Found {len(schedules)} total historical schedules for {category}.")
        return schedules
    except Exception as e:
        log.error(f"Error fetching schedules for {category}: {e}")
        return []


def import_schedules_for_category(category: str):
    schedules = fetch_ranking_schedules(category)
    if not schedules:
        log.error(f"No schedules found for {category}.")
        return

    db = SessionLocal()
    
    # Pre-cache historical teams into memory
    teams_cache = {}
    existing_teams = db.query(FootballHistoricalTeam).filter(
        FootballHistoricalTeam.category == category
    ).all()
    for t in existing_teams:
        teams_cache[t.name.lower()] = t.id

    total_rankings_added = 0
    
    for idx, sched in enumerate(schedules):
        sid = sched['id']
        year = sched['year']
        month = sched['month']
        day = sched['day']
        
        api_url = f"{FIFA_API_BASE}?rankingScheduleId={sid}&language=en"
        
        try:
            r = requests.get(api_url, headers=HEADERS, timeout=15)
            if r.status_code != 200:
                log.warning(f"Failed to fetch schedule {sid} (HTTP {r.status_code})")
                continue
                
            data = r.json()
            results = data.get('Results', [])
            if not results:
                continue
                
            rankings_to_insert = []
            
            for entry in results:
                raw_name = entry.get('TeamName', [{}])[0].get('Description') if entry.get('TeamName') else None
                if not raw_name:
                    continue
                    
                team_name = clean_team_name(raw_name)
                rank = entry.get('Rank')
                if rank is None:
                    continue
                    
                points = float(entry.get('PTS') or entry.get('TotalPoints') or 0.0)
                confederation = entry.get('ConfederationName')
                
                # Check or create historical team
                team_key = team_name.lower()
                team_id = teams_cache.get(team_key)
                if not team_id:
                    new_team = FootballHistoricalTeam(
                        name=team_name,
                        country=team_name,
                        confederation=confederation,
                        category=category
                    )
                    db.add(new_team)
                    db.flush() # assign ID
                    team_id = new_team.id
                    teams_cache[team_key] = team_id
                    
                # Check if ranking already exists
                existing_r = db.query(FootballHistoricalRanking.id).filter(
                    FootballHistoricalRanking.team_id == team_id,
                    FootballHistoricalRanking.ranking_year == year,
                    FootballHistoricalRanking.ranking_month == month,
                    FootballHistoricalRanking.ranking_date == day
                ).first()
                
                if not existing_r:
                    rankings_to_insert.append(FootballHistoricalRanking(
                        team_id=team_id,
                        points=points,
                        rank=rank,
                        ranking_date=day,
                        ranking_month=month,
                        ranking_year=year
                    ))
                    
            if rankings_to_insert:
                db.bulk_save_objects(rankings_to_insert)
                db.commit()
                total_rankings_added += len(rankings_to_insert)
                
            if (idx + 1) % 10 == 0 or idx == len(schedules) - 1:
                log.info(f"[{category.upper()}] Processed schedule {idx + 1}/{len(schedules)}: {sched['iso'][:10]} - Added {total_rankings_added} ranking checkpoints so far.")
                
            # Rate limiting sleep
            time.sleep(0.1)
            
        except Exception as e:
            log.error(f"Error processing schedule {sid}: {e}")
            db.rollback()
            
    db.close()
    log.info(f"[{category.upper()}] Import complete! Total ranking checkpoints stored: {total_rankings_added}")


def main():
    log.info("Starting Historical Football National Teams Ranking Import...")
    log.info("--- Importing Men's National Team Rankings History ---")
    import_schedules_for_category("men")
    
    log.info("--- Importing Women's National Team Rankings History ---")
    import_schedules_for_category("women")
    
    log.info("Historical Football Ranking Import completed successfully.")

if __name__ == "__main__":
    main()
