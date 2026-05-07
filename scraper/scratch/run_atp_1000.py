import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.utils.logger import log

def run_atp_test():
    atp = ATPScraper()
    # Try to scrape up to 1000
    atp.scrape_rankings(limit=1000)

if __name__ == "__main__":
    run_atp_test()
