import sys
import os

# Add project root and backend to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..', '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))
sys.path.append(os.path.join(project_root, 'scraper'))

from scraper.scrapers.wiki_scraper import WikiScraper
from scraper.persistence import save_player, SessionLocal
from app.models.player import Player
from scraper.utils.logger import log

def fix_top_player_images():
    wiki = WikiScraper()
    db = SessionLocal()
    
    try:
        # Get players whose images are from ATP
        players = db.query(Player).filter(Player.image_url.like('%atptour.com%')).limit(40).all()
        
        log.info(f"Attempting to fix {len(players)} player images...")
        
        for player in players:
            log.info(f"Updating image for {player.name}...")
            wiki_data = wiki.enrich_player(player.name)
            if wiki_data and 'image_url' in wiki_data:
                new_url = wiki_data['image_url']
                log.info(f"Found Wiki image for {player.name}: {new_url}")
                player.image_url = new_url
            else:
                log.warning(f"Could not find Wiki image for {player.name}")
        
        db.commit()
        log.info("Finished updating player images.")
    except Exception as e:
        db.rollback()
        log.error(f"Error in fix script: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    fix_top_player_images()
