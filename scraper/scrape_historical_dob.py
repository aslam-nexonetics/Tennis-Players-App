#!/usr/bin/env python3
"""
Scrape Date of Birth (DOB) and Pictures for Historical Table Tennis Players.
Utilizes the Wikidata public entities and Special:EntityData APIs to resolve players
missing birth dates and enriches the database records.
"""

import os
import sys
import argparse
import time
import urllib.parse
import requests
from datetime import datetime
from dotenv import load_dotenv
from sqlalchemy import func, text

# Set up paths
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

# Load environment variables
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from sqlalchemy import event
from app.db.session import SessionLocal, engine
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer, TableTennisHistoricalRanking
from scraper.utils.logger import log

@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    # Only run PRAGMAs for SQLite connections
    conn_type = type(dbapi_connection).__name__.lower()
    if "sqlite" in conn_type:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA synchronous = OFF")
        cursor.execute("PRAGMA journal_mode = MEMORY")
        cursor.close()

HEADERS = {
    "User-Agent": "TableTennisPlayerDatabaseScraper/1.0 (contact: info@example.com; github.com/nexonetics/tennis_app)"
}

def clean_name(name_str):
    if not name_str:
        return ""
    import re
    return re.sub(r'\s+', ' ', name_str).strip()

def get_wikidata_player_details(first_name, last_name, delay=1.0):
    """
    Search Wikidata for a table tennis player with the given names.
    Returns a dict with birth_year, birth_month, birth_date, picture, and entity_id if found.
    """
    first_name = clean_name(first_name)
    last_name = clean_name(last_name)
    
    name1 = f"{first_name} {last_name}".strip()
    name2 = f"{last_name} {first_name}".strip()
    
    queries = []
    if name1:
        queries.append(f"{name1} table tennis")
    if name2 and name2 != name1:
        queries.append(f"{name2} table tennis")
    if name1:
        queries.append(name1)
    if name2 and name2 != name1:
        queries.append(name2)
        
    # Remove duplicates but keep order
    seen = set()
    queries = [q for q in queries if not (q in seen or seen.add(q))]
    
    for search_term in queries:
        url_search = "https://www.wikidata.org/w/api.php"
        params_search = {
            "action": "wbsearchentities",
            "search": search_term,
            "language": "en",
            "format": "json"
        }
        
        try:
            log.debug(f"Querying Wikidata search for: '{search_term}'")
            r = requests.get(url_search, params=params_search, headers=HEADERS, timeout=5)
            r.raise_for_status()
            search_results = r.json().get("search", [])
            if not search_results:
                time.sleep(delay)
                continue
                
            # Inspect up to 3 candidates
            for result in search_results[:3]:
                entity_id = result["id"]
                description = result.get("description", "")
                
                # Fetch detailed entity claims
                url_data = f"https://www.wikidata.org/wiki/Special:EntityData/{entity_id}.json"
                r_data = requests.get(url_data, headers=HEADERS, timeout=5)
                r_data.raise_for_status()
                
                entity_data = r_data.json().get("entities", {}).get(entity_id, {})
                claims = entity_data.get("claims", {})
                
                # Verify instance of Human (Q5)
                p31 = claims.get("P31", [])
                is_human = False
                for c in p31:
                    if c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id") == "Q5":
                        is_human = True
                        break
                        
                if not is_human:
                    continue
                    
                # Verify table tennis occupation
                # Q13382519 and Q11903303 both represent Table Tennis Player
                is_tt_player = False
                p106 = claims.get("P106", [])
                for occ in p106:
                    occ_id = occ.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id")
                    if occ_id in ["Q13382519", "Q11903303"]:
                        is_tt_player = True
                        break
                        
                # Fallback check on description
                desc_lower = description.lower()
                if not is_tt_player:
                    if "table tennis" in desc_lower or "ping pong" in desc_lower or "ittf" in desc_lower:
                        is_tt_player = True
                        
                if is_tt_player:
                    log.info(f"Matched Wikidata entity {entity_id} for '{name1}' ({description})")
                    enrichment = {
                        "entity_id": entity_id,
                        "birth_year": None,
                        "birth_month": None,
                        "birth_date": None,
                        "picture": None,
                        "country_code": None
                    }
                    
                    # Extract Birth Date (P569)
                    p569 = claims.get("P569", [])
                    if p569:
                        time_val = p569[0].get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("time")
                        if time_val:
                            # Format: "+1991-04-12T00:00:00Z" or "+1990-00-00..."
                            time_str = time_val.lstrip("+")
                            date_part = time_str.split("T")[0]
                            parts = date_part.split("-")
                            if len(parts) >= 3:
                                try:
                                    year = int(parts[0])
                                    month = int(parts[1]) if parts[1] != "00" else None
                                    day = int(parts[2]) if parts[2] != "00" else None
                                    
                                    # Sanity check
                                    if 1800 < year <= datetime.now().year:
                                        enrichment["birth_year"] = year
                                        enrichment["birth_month"] = month
                                        enrichment["birth_date"] = day
                                except ValueError:
                                    pass
                                    
                    # Extract Picture (P18)
                    p18 = claims.get("P18", [])
                    if p18:
                        filename = p18[0].get("mainsnak", {}).get("datavalue", {}).get("value")
                        if filename:
                            encoded_filename = urllib.parse.quote(filename)
                            enrichment["picture"] = f"https://commons.wikimedia.org/wiki/Special:FilePath/{encoded_filename}"
                            
                    time.sleep(delay)
                    return enrichment
                    
                time.sleep(delay)
        except Exception as e:
            log.error(f"Error querying Wikidata for '{search_term}': {e}")
            time.sleep(delay)
            
    return None

def main():
    parser = argparse.ArgumentParser(description="Scrape and Enrich Table Tennis Player DOBs.")
    parser.add_argument("--limit", type=int, default=100, help="Number of players to enrich via Wikidata (default: 100)")
    parser.add_argument("--delay", type=float, default=1.0, help="Delay in seconds between Wikidata requests (default: 1.0)")
    parser.add_argument("--all", action="store_true", help="Scrape all players missing DOB via Wikidata (WARNING: long time)")
    parser.add_argument("--skip-wikidata", action="store_true", help="Only run the local database sync, do not query Wikidata")
    args = parser.parse_args()
    
    db = SessionLocal()
    try:
        # Phase 1: Local Sync from active players table
        log.info("Phase 1: Syncing DOBs locally from active players table...")
        dialect_name = engine.dialect.name
        log.info(f"Database dialect: {dialect_name}")
        
        row_count = 0
        if dialect_name == "postgresql":
            sql = """
            UPDATE tt_players_historical hp
            SET 
              birth_year = CAST(EXTRACT(YEAR FROM ap.birth_date) AS INTEGER),
              birth_month = CAST(EXTRACT(MONTH FROM ap.birth_date) AS INTEGER),
              birth_date = CAST(EXTRACT(DAY FROM ap.birth_date) AS INTEGER),
              picture = COALESCE(hp.picture, ap.image_url)
            FROM table_tennis_players ap
            WHERE 
              hp.birth_year IS NULL
              AND ap.birth_date IS NOT NULL
              AND (
                LOWER(hp.first_name || ' ' || hp.last_name) = LOWER(ap.name)
                OR LOWER(hp.last_name || ' ' || hp.first_name) = LOWER(ap.name)
              );
            """
            result = db.execute(text(sql))
            row_count = result.rowcount
        elif dialect_name == "sqlite":
            sql = """
            UPDATE tt_players_historical
            SET
              birth_year = CAST(strftime('%Y', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              birth_month = CAST(strftime('%m', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              birth_date = CAST(strftime('%d', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              picture = COALESCE(picture, (
                SELECT image_url FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              ))
            WHERE birth_year IS NULL AND EXISTS (
              SELECT 1 FROM table_tennis_players 
              WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                 OR LOWER(name) = LOWER(last_name || ' ' || first_name)
            );
            """
            result = db.execute(text(sql))
            row_count = result.rowcount
            
        db.commit()
        log.info(f"Local sync complete. Enriched {row_count} players locally.")
        
        if args.skip_wikidata:
            return
            
        # Phase 2: Wikidata Scraping
        log.info("\nPhase 2: Scraping remaining players from Wikidata...")
        
        # Find players with missing birth information
        # Order by career-high rank (minimum rank) so we prioritize the most prominent/active players
        query = db.query(TableTennisHistoricalPlayer).\
            outerjoin(TableTennisHistoricalRanking).\
            filter(TableTennisHistoricalPlayer.birth_year == None).\
            group_by(TableTennisHistoricalPlayer.id).\
            order_by(func.min(TableTennisHistoricalRanking.rank).asc())
            
        if not args.all:
            query = query.limit(args.limit)
            
        players = query.all()
        total_found = len(players)
        
        if total_found == 0:
            log.info("No players found missing date of birth.")
            return
            
        log.info(f"Starting Wikidata enrichment for {total_found} players...")
        
        success_count = 0
        image_count = 0
        
        for idx, player in enumerate(players):
            full_name = f"{player.first_name} {player.last_name}"
            log.info(f"[{idx+1}/{total_found}] Processing: {full_name} ({player.country or 'Unknown'})")
            
            enrichment = get_wikidata_player_details(player.first_name, player.last_name, delay=args.delay)
            
            if enrichment:
                updated = False
                
                # Check and update birth date details
                if enrichment["birth_year"]:
                    player.birth_year = enrichment["birth_year"]
                    player.birth_month = enrichment["birth_month"]
                    player.birth_date = enrichment["birth_date"]
                    updated = True
                    success_count += 1
                    dob_str = f"{enrichment['birth_year']}-{enrichment['birth_month'] or 'XX'}-{enrichment['birth_date'] or 'XX'}"
                    log.info(f"  -> Found Birth Date: {dob_str}")
                    
                # Enrich picture if not already present
                if enrichment["picture"] and not player.picture:
                    player.picture = enrichment["picture"]
                    updated = True
                    image_count += 1
                    log.info(f"  -> Found Profile Image: {enrichment['picture']}")
                    
                if updated:
                    db.commit()
            else:
                log.info("  -> No matching player found on Wikidata.")
                
        log.info("\nEnrichment Process Completed!")
        log.info(f"Successfully enriched birth dates for {success_count}/{total_found} players.")
        log.info(f"Added profile images for {image_count} players.")
        
    except Exception as e:
        log.error(f"Error during enrichment: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
