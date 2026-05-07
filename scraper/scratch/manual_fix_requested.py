import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '../..'))
sys.path.append(project_root)

from scraper.scrapers.atp_scraper import ATPScraper
from scraper.persistence import save_player

def manual_fix():
    atp = ATPScraper()
    # Scrape segment 501-1000
    for start in range(500, 1000, 100):
        r = f"{start+1}-{start+100}"
        url = f"https://www.atptour.com/en/rankings/singles?rankRange={r}"
        print(f"Manually fetching range {r}...")
        soup = atp.get_soup_playwright(url)
        if not soup: continue
        
        table = soup.select_one("table.rankings-table") or soup.select_one("table")
        if not table: continue
        
        rows = table.select("tbody tr")
        print(f"Searching in {len(rows)} rows...")
        for row in rows:
            try:
                rank_cell = row.select_one("td.rank")
                player_link = row.select_one(".name a")
                if not rank_cell or not player_link: continue
                
                rank = rank_cell.text.strip().replace("T", "")
                player_name_table = player_link.text.strip()
                player_url = player_link.get("href", "")
                
                # Link format: /en/players/svyatoslav-gulin/g0e2/overview
                parts = player_url.split("/")
                if "players" in parts:
                    idx = parts.index("players")
                    slug = parts[idx + 1]
                    name = " ".join(slug.split("-")).title()
                else:
                    name = player_name_table
                
                # print(f"Checking: {name} (Rank {rank})")
                if "Gulin" in name or "Klok" in name or "Gulin" in player_name_table or "Klok" in player_name_table:
                    print(f"!!! FOUND TARGET !!!: {name} (Rank {rank})")
                    player_data = {
                        "name": name,
                        "ranking": int(rank),
                        "gender": "M",
                        "source": "ATP Tour"
                    }
                    full_url = f"https://www.atptour.com{player_url}"
                    atp.enrich_from_atp(full_url, player_data)
                    save_player(player_data)
                    print(f"SAVED: {name}")
            except Exception as e: 
                continue

if __name__ == "__main__":
    manual_fix()
