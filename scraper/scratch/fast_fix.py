import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.scrapers.wta_scraper import WTAScraper
from scraper.utils.logger import log

def run_fast_scrape():
    # ATP Fast Scrape (Limit 2000)
    # Enrichment only for top 100 or priority players
    atp = ATPScraper()
    print("Starting fast ATP scrape (Limit 2000)...")
    atp.scrape_rankings(limit=2000)
    
    # WTA Fast Scrape (Limit 2000)
    wta = WTAScraper()
    print("Starting fast WTA scrape (Limit 2000)...")
    wta.scrape_rankings(limit=2000)

if __name__ == "__main__":
    run_fast_scrape()
