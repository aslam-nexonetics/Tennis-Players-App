import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.utils.logger import log
from scraper.persistence import save_player
from backend.app.db.session import engine
from sqlalchemy import text

def fix():
    # 1. Clear current tennis players to avoid abbreviated duplicates
    with engine.connect() as conn:
        print("Clearing existing tennis players...")
        conn.execute(text("DELETE FROM players"))
        conn.commit()

    atp = ATPScraper()
    
    print("Running ATP scraper for top 1000 (Full Enrichment and Full Names)...")
    atp.scrape_rankings(limit=1000)

if __name__ == "__main__":
    fix()
