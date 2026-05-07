import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.persistence import save_player

def manual_add_gulin():
    atp = ATPScraper()
    # Svyatoslav Gulin is Rank 498
    # Link: /en/players/svyatoslav-gulin/g0e2/overview
    name = "Svyatoslav Gulin"
    rank = 498
    player_url = "/en/players/svyatoslav-gulin/g0e2/overview"
    
    player_data = {
        "name": name,
        "ranking": rank,
        "gender": "M",
        "source": "ATP Tour"
    }
    
    print(f"Manually adding {name} (Rank {rank})...")
    full_url = f"https://www.atptour.com{player_url}"
    atp.enrich_from_atp(full_url, player_data)
    save_player(player_data)
    print(f"DONE: {name} is now in the database.")

if __name__ == "__main__":
    manual_add_gulin()
