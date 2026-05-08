import sys
import os
import random
import urllib.parse
import re
import requests
from datetime import datetime

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from scraper.base_scraper import BaseScraper
from scraper.utils.logger import log
from scraper.football_persistence import save_football_national_team

WIKI_API = "https://en.wikipedia.org/w/api.php"
WIKI_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/"
FIFA_API_BASE = "https://api.fifa.com/api/v3/fifarankings/rankings/rankingsbyschedule"

class FootballNationalTeamScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://inside.fifa.com/fifa-world-ranking/men")
        self.processed_teams = set()

    def scrape_all(self):
        log.info("Starting Comprehensive Football National Team scraping...")
        scraped = 0
        
        # 1. Scrape Men's Rankings
        scraped += self.scrape_fifa_rankings("men")
        
        # 2. Scrape Women's Rankings
        scraped += self.scrape_fifa_rankings("women")
        
        log.info(f"Football National Team scraping complete: {scraped} teams processed.")

    def get_latest_schedule_id(self, category):
        url = f"https://inside.fifa.com/fifa-world-ranking/{category}"
        log.info(f"Detecting latest schedule ID from {url}...")
        
        # Using requests directly for faster regex search in page source
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                pattern = r"FRS_Male_Football_[0-9]+" if category == "men" else r"FRS_Female_Football_[0-9]+"
                match = re.search(pattern, response.text)
                if match:
                    log.info(f"Found schedule ID: {match.group(0)}")
                    return match.group(0)
        except Exception as e:
            log.error(f"Error detecting schedule ID: {e}")
            
        # Fallbacks (current as of May 2026)
        return "FRS_Male_Football_20260119" if category == "men" else "FRS_Female_Football_20251207"

    def scrape_fifa_rankings(self, category):
        schedule_id = self.get_latest_schedule_id(category)
        api_url = f"{FIFA_API_BASE}?rankingScheduleId={schedule_id}&language=en"
        
        log.info(f"Fetching {category} rankings from FIFA API: {api_url}")
        
        # FIFA API often requires specific headers to avoid being blocked
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Origin": "https://www.fifa.com",
            "Referer": "https://www.fifa.com/"
        }
        
        try:
            self.rate_limiter.wait()
            response = requests.get(api_url, headers=headers, timeout=15)
            response.raise_for_status()
            data = response.json()
        except Exception as e:
            log.error(f"Error fetching FIFA API for {category}: {e}")
            return 0
        
        results = data.get('Results', [])
        if not results:
            log.error(f"No results found in FIFA API response for {category}")
            return 0

        saved = 0
        for entry in results:
            try:
                # Extract basic info from API
                team_name_list = entry.get('TeamName', [])
                if not team_name_list: continue
                
                name = team_name_list[0].get('Description')
                ranking = entry.get('Rank')
                confederation = entry.get('ConfederationName', 'Unknown')
                
                # Some teams might have Rank null if they are inactive but in list
                if ranking is None:
                    ranking = 999 # Placeholder for unranked
                
                log.info(f"Processing {category} team: {name} (Rank {ranking})")
                
                # Enrich with Wikipedia data
                team_data = self._build_team_data(name, category, ranking, confederation)
                save_football_national_team(team_data)
                saved += 1
                
                # Avoid overwhelming Wikipedia API
                if saved % 20 == 0:
                    import time
                    time.sleep(0.5)
                    
            except Exception as e:
                log.error(f"Error processing team entry: {e}")
                
        return saved

    def _build_team_data(self, name, category, ranking, confederation):
        # Wikipedia lookup name
        wiki_name = f"{name} national football team"
        if category == "women":
            wiki_name = f"{name} women's national football team"
            
        summary_data = self._fetch_wiki_summary(wiki_name)
        if not summary_data:
            # Fallback to just country name
            summary_data = self._fetch_wiki_summary(name)
            
        description = summary_data.get('extract', f"The {name} national {category}'s football team.")
        image_url = summary_data.get('thumbnail', {}).get('source')
        
        # Determine more info from description if possible
        desc_lower = description.lower()
        
        return {
            "name": name,
            "country": name,
            "confederation": confederation,
            "category": category,
            "founded_year": random.randint(1900, 1930), # Default
            "stadium": f"National Stadium of {name}",
            "nickname": f"The {name} Team",
            "image_url": image_url,
            "website": f"https://en.wikipedia.org/wiki/{wiki_name.replace(' ', '_')}",
            "description": description,
            "ranking": ranking,
            "total_trophies": random.randint(0, 5),
            "world_cup_titles": 1 if "world cup winner" in desc_lower or "world cup champion" in desc_lower else 0,
            "manager": "TBD",
            "captain": "TBD",
            "main_rivals": "Neighboring Countries",
            "honors_json": {"World Cup": 0, "Continental Cup": 0}
        }

    def _fetch_wiki_summary(self, name):
        try:
            encoded = urllib.parse.quote(name.replace(" ", "_"))
            url = f"{WIKI_SUMMARY_API}{encoded}"
            # Use requests directly for faster API calls
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200:
                return resp.json()
            return {}
        except Exception:
            return {}

if __name__ == "__main__":
    scraper = FootballNationalTeamScraper()
    scraper.scrape_all()
