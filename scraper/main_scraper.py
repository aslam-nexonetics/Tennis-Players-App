import sys
import os
import argparse
# Add the project root to sys.path so 'scraper' and 'backend' modules can be found
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.scrapers.wta_scraper import WTAScraper
from scraper.scrapers.wiki_scraper import WikiScraper
from scraper.scrapers.wtt_scraper import WTTScraper
from scraper.utils.logger import log
from scraper.persistence import SessionLocal, Player


def run_tennis_scraper():
    log.info("Starting tennis player scraper...")

    atp = ATPScraper()
    wta = WTAScraper()
    wiki = WikiScraper()

    # 1. Scrape Rankings
    atp.scrape_rankings(limit=200)
    wta.scrape_rankings(limit=200)

    # 2. Enrich missing data
    db = SessionLocal()
    try:
        players = db.query(Player).all()
        for player in players:
            if not player.height or not player.birth_date:
                enriched = wiki.enrich_player(player.name)
                if enriched:
                    for key, value in enriched.items():
                        if not getattr(player, key):
                            setattr(player, key, value)
                    db.commit()
    except Exception as e:
        log.error(f"Error during enrichment phase: {e}")
    finally:
        db.close()

    log.info("Tennis scraper run completed successfully.")


def run_tt_scraper():
    log.info("Starting table tennis player scraper...")
    wtt = WTTScraper()
    wtt.scrape_rankings(limit=200)
    log.info("Table tennis scraper run completed successfully.")


def run_scraper():
    """Legacy entry point — runs tennis scraper only."""
    run_tennis_scraper()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tennis & Table Tennis scraper")
    parser.add_argument("--tt-only", action="store_true", help="Run only the table tennis scraper")
    parser.add_argument("--all", action="store_true", help="Run both tennis and table tennis scrapers")
    args = parser.parse_args()

    if args.tt_only:
        run_tt_scraper()
    elif args.all:
        run_tennis_scraper()
        run_tt_scraper()
    else:
        # Default: run tennis scraper (backward compat)
        run_tennis_scraper()
