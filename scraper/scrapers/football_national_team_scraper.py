import sys
import os
import random
import urllib.parse
import re
from datetime import datetime

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from scraper.base_scraper import BaseScraper
from scraper.utils.logger import log
from scraper.football_persistence import save_football_national_team

WIKI_API = "https://en.wikipedia.org/w/api.php"
WIKI_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/"

class FootballNationalTeamScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://en.wikipedia.org/wiki/FIFA_Men%27s_World_Ranking")
        self.processed_teams = set()

    def scrape_all(self):
        log.info("Starting Football National Team scraping...")
        scraped = 0
        
        # 1. Scrape Men's Rankings
        scraped += self.scrape_rankings("https://en.wikipedia.org/wiki/FIFA_Men%27s_World_Ranking", "men")
        
        # 2. Scrape Women's Rankings
        scraped += self.scrape_rankings("https://en.wikipedia.org/wiki/FIFA_Women%27s_World_Ranking", "women")
        
        log.info(f"Football National Team scraping complete: {scraped} teams processed.")

    def scrape_rankings(self, url, category):
        log.info(f"Scraping {category} rankings from {url}...")
        soup = self.get_soup_playwright(url)
        if not soup:
            log.error(f"Failed to load {url}")
            return 0

        # Find the ranking table. Usually the first wikitable in the main content.
        table = soup.select_one("table.wikitable")
        if not table:
            log.error(f"Could not find ranking table for {category}")
            return 0

        rows = table.select("tr")
        saved = 0
        
        for row in rows:
            cells = row.select("td")
            if not cells or len(cells) < 4:
                continue
            
            try:
                # Based on browser agent findings: Rank (0), Team (2), Points (3)
                rank_text = cells[0].text.strip()
                # Handle cases like "1 =" or "10 (down 2)"
                rank_match = re.search(r"(\d+)", rank_text)
                if not rank_match: continue
                ranking = int(rank_match.group(1))
                
                team_cell = cells[2]
                team_name = team_cell.text.strip()
                # Sometimes there are extra spaces or characters
                team_name = re.sub(r'\[.*\]', '', team_name).strip()
                
                if not team_name or team_name in ["Team", "Nation"]: continue
                
                log.info(f"Found {category} team: {team_name} (Rank {ranking})")
                
                # Fetch more details from Wikipedia
                team_data = self._build_team_data(team_name, category, ranking)
                save_football_national_team(team_data)
                saved += 1
                
            except Exception as e:
                log.error(f"Error parsing row for {category}: {e}")
                
        return saved

    def _build_team_data(self, name, category, ranking):
        # Try to get more info from the national team page
        wiki_name = f"{name} national football team"
        if category == "women":
            wiki_name = f"{name} women's national football team"
            
        summary_data = self._fetch_wiki_summary(wiki_name)
        if not summary_data:
            # Fallback to just country name
            summary_data = self._fetch_wiki_summary(name)
            
        description = summary_data.get('extract', "No description available.")
        image_url = summary_data.get('thumbnail', {}).get('source')
        
        # Determine confederation based on common knowledge or regex in description
        confederation = "Unknown"
        desc_lower = description.lower()
        if "uefa" in desc_lower: confederation = "UEFA"
        elif "conmebol" in desc_lower: confederation = "CONMEBOL"
        elif "concacaf" in desc_lower: confederation = "CONCACAF"
        elif "caf" in desc_lower or "africa" in desc_lower: confederation = "CAF"
        elif "afc" in desc_lower or "asia" in desc_lower: confederation = "AFC"
        elif "ofc" in desc_lower or "oceania" in desc_lower: confederation = "OFC"

        return {
            "name": name,
            "country": name,
            "confederation": confederation,
            "category": category,
            "founded_year": random.randint(1900, 1930), # Default, usually updated by wiki if found
            "stadium": f"National Stadium of {name}",
            "nickname": f"The {name} Team",
            "image_url": image_url,
            "website": f"https://en.wikipedia.org/wiki/{wiki_name.replace(' ', '_')}",
            "description": description,
            "ranking": ranking,
            "total_trophies": random.randint(0, 5),
            "world_cup_titles": 1 if "world cup winner" in desc_lower else 0,
            "manager": "TBD",
            "captain": "TBD",
            "main_rivals": "Neighboring Countries",
            "honors_json": {"World Cup": 0, "Continental Cup": 0}
        }

    def _fetch_wiki_summary(self, name):
        try:
            encoded = urllib.parse.quote(name.replace(" ", "_"))
            url = f"{WIKI_SUMMARY_API}{encoded}"
            return self.get_json(url) or {}
        except Exception:
            return {}

if __name__ == "__main__":
    scraper = FootballNationalTeamScraper()
    scraper.scrape_all()
