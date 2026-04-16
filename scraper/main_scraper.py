import sys
import os
# Add the project root to sys.path so 'scraper' and 'backend' modules can be found
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.scrapers.wta_scraper import WTAScraper
from scraper.scrapers.wiki_scraper import WikiScraper
from scraper.utils.logger import log
from scraper.persistence import SessionLocal, Player

def run_scraper():
    log.info("Starting tennis player scraper...")
    
    atp = ATPScraper()
    wta = WTAScraper()
    wiki = WikiScraper()

    # 1. Scrape Rankings
    atp.scrape_rankings(limit=50) # Limit for now to avoid long runs
    wta.scrape_rankings(limit=50)

    # 2. Enrich missing data
    db = SessionLocal()
    try:
        players = db.query(Player).all()
        for player in players:
            # Only enrich if essential data is missing or recently added
            # For simplicity, we'll check if height/birth_date is missing
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

    log.info("Scraper run completed successfully.")

if __name__ == "__main__":
    run_scraper()
