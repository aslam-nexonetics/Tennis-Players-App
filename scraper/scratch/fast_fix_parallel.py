import sys
import os
import threading

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.scrapers.wta_scraper import WTAScraper

def run_atp():
    atp = ATPScraper()
    print("Starting ATP scrape (Limit 5000)...")
    atp.scrape_rankings(limit=5000)

def run_wta():
    wta = WTAScraper()
    print("Starting WTA scrape (Limit 5000)...")
    wta.scrape_rankings(limit=5000)

if __name__ == "__main__":
    # Run both in parallel threads
    t1 = threading.Thread(target=run_atp)
    t2 = threading.Thread(target=run_wta)
    
    t1.start()
    t2.start()
    
    t1.join()
    t2.join()
