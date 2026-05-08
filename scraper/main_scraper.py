import sys
import os
import argparse

# Add current directory and project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(script_dir)
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

# Local imports from scrapers/ subdirectory
from scrapers.atp_scraper import ATPScraper
from scrapers.wta_scraper import WTAScraper
from scrapers.wtt_scraper import WTTScraper
from scrapers.football_national_team_scraper import FootballNationalTeamScraper
from scrapers.basketball_club_scraper import BasketballClubScraper
from utils.logger import log

def run_tennis_scraper():
    log.info("Starting Tennis Scraper...")
    atp = ATPScraper()
    atp.scrape_rankings(limit=5000)
    wta = WTAScraper()
    wta.scrape_rankings(limit=5000)

def run_tt_scraper():
    log.info("Starting Table Tennis Scraper...")
    wtt = WTTScraper()
    wtt.scrape_rankings(limit=10000)

def run_football_scraper():
    log.info("Starting Football National Team Scraper...")
    fb = FootballNationalTeamScraper()
    fb.scrape_all()

def run_basketball_scraper():
    log.info("Starting Basketball Club Scraper...")
    bb = BasketballClubScraper()
    bb.scrape_clubs(limit=10000)

def main():
    parser = argparse.ArgumentParser(description="Multi-Sport Web Scraper")
    parser.add_argument("--tennis-only", action="store_true", help="Run only Tennis scraper")
    parser.add_argument("--tt-only", action="store_true", help="Run only Table Tennis scraper")
    parser.add_argument("--football-only", action="store_true", help="Run only Football Club scraper")
    parser.add_argument("--basketball-only", action="store_true", help="Run only Basketball Club scraper")
    
    args = parser.parse_args()

    if args.tennis_only:
        run_tennis_scraper()
    elif args.tt_only:
        run_tt_scraper()
    elif args.football_only:
        run_football_scraper()
    elif args.basketball_only:
        run_basketball_scraper()
    else:
        # Run all scrapers sequentially
        run_tennis_scraper()
        run_tt_scraper()
        run_football_scraper()
        run_basketball_scraper()

if __name__ == "__main__":
    main()
