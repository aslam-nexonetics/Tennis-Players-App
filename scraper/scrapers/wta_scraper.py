import urllib.parse
import re
from datetime import datetime, timedelta
from scraper.base_scraper import BaseScraper
from scraper.utils.logger import log
from scraper.persistence import save_player
from scraper.scrapers.wiki_scraper import WikiScraper

WIKI_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/"

class WTAScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://api.wtatennis.com/tennis/players/ranked")
        self.wiki = WikiScraper()

    def scrape_rankings(self, limit=1500):
        log.info(f"Scraping WTA rankings from API (limit {limit})...")
        
        players_scraped = 0
        page = 0
        page_size = 100
        today = datetime.now().strftime("%Y-%m-%d")

        while players_scraped < limit:
            url = f"{self.base_url}?metric=SINGLES&type=rankSingles&sort=asc&at={today}&pageSize={page_size}&page={page}"
            data = self.get_json(url)
            
            if not data or not isinstance(data, list) or len(data) == 0:
                log.info(f"No more WTA players found at page {page}")
                break

            for item in data:
                if players_scraped >= limit:
                    break
                
                try:
                    player_info = item.get('player', {})
                    ranking = item.get('ranking')
                    
                    first_name = player_info.get('firstName', '')
                    last_name = player_info.get('lastName', '')
                    name = f"{first_name} {last_name}".strip()
                    
                    if not name or not ranking:
                        continue

                    country = player_info.get('countryCode', 'Unknown')
                    birth_date_str = player_info.get('dateOfBirth')
                    birth_date = None
                    if birth_date_str:
                        try:
                            birth_date = datetime.strptime(birth_date_str, "%Y-%m-%d").date()
                        except:
                            pass

                    log.info(f"Found WTA {name} (Rank {ranking}). Enriching...")
                    wiki_data = {}
                    if ranking <= 1000:
                        wiki_data = self.wiki.enrich_player(name) or {}

                    player_data = {
                        "name": name,
                        "ranking": ranking,
                        "highest_ranking": wiki_data.get('highest_ranking', ranking),
                        "highest_ranking_date": wiki_data.get('highest_ranking_date'),
                        "birth_date": birth_date or wiki_data.get('birth_date'),
                        "height": wiki_data.get('height'),
                        "weight": wiki_data.get('weight'),
                        "playing_style": wiki_data.get('playing_style'),
                        "country": wiki_data.get('country', country),
                        "wins": wiki_data.get('wins', 0),
                        "losses": wiki_data.get('losses', 0),
                        "titles": wiki_data.get('titles', 0),
                        "turned_pro": wiki_data.get('turned_pro'),
                        "prize_money": wiki_data.get('prize_money'),
                        "gender": "F",
                        "image_url": wiki_data.get('image_url'),
                        "source": "WTA Tour Official"
                    }

                    # Parse highest ranking if string
                    if isinstance(player_data['highest_ranking'], str):
                        match = re.search(r"(\d+)", player_data['highest_ranking'])
                        player_data['highest_ranking'] = int(match.group(1)) if match else ranking

                    save_player(player_data)
                    players_scraped += 1
                except Exception as e:
                    log.error(f"Error parsing WTA API item: {e}")

            page += 1
            if len(data) < page_size:
                break

    def _fetch_wiki_image(self, name):
        try:
            encoded = urllib.parse.quote(name.replace(" ", "_"))
            url = f"{WIKI_SUMMARY_API}{encoded}"
            data = self.get_json(url)
            if data and 'thumbnail' in data:
                return data['thumbnail'].get('source')
        except Exception:
            pass
        return None
