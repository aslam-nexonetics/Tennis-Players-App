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
        super().__init__("https://en.wikipedia.org/wiki/WTA_rankings")
        self.wiki = WikiScraper()

    def scrape_rankings(self, limit=100):
        log.info(f"Scraping WTA rankings from official site (limit {limit})...")
        url = "https://www.wtatennis.com/rankings/singles"
        soup = self.get_soup_playwright(url)
        if not soup:
            log.error("Failed to load WTA rankings via Playwright.")
            return

        players_scraped = 0
        # Target the rankings table
        table = soup.select_one("table.rankings-table")
        if not table:
            table = soup.select_one("table")
        
        if not table:
            log.error("Could not find WTA rankings table.")
            return

        rows = table.select("tbody tr")
        for row in rows:
            if players_scraped >= limit:
                break
            
            try:
                # Improved extraction for WTA site:
                ranking = None
                rank_el = row.select_one(".player-row__rank")
                if rank_el:
                    ranking = int(re.search(r"(\d+)", rank_el.text).group(1))
                
                # Preferred clean name from data attribute
                name = row.get('data-player-name')
                if not name:
                    player_cell = row.select_one(".rankings-table__player") or row.select_one(".player-cell")
                    if player_cell:
                        name = " ".join(player_cell.text.split()).strip()
                        name = re.sub(r'\s+[A-Z]{3}$', '', name)
                
                if not name or not ranking: continue

                country = row.get('data-player-country')
                if not country:
                    country_cell = row.select_one(".rankings-table__country") or row.select_one(".player-row__cell--country")
                    if country_cell:
                        country = country_cell.text.strip()
                
                country = country or "Unknown"
                
                log.info(f"Found {name} (Rank {ranking}). Enriching...")
                wiki_data = self.wiki.enrich_player(name) or {}

                player_data = {
                    "name": name,
                    "ranking": ranking,
                    "highest_ranking": wiki_data.get('highest_ranking', ranking),
                    "highest_ranking_date": wiki_data.get('highest_ranking_date'),
                    "birth_date": wiki_data.get('birth_date'),
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
                    "source": "WTA Tour / Wikipedia"
                }

                # Parse highest ranking if string
                if isinstance(player_data['highest_ranking'], str):
                    match = re.search(r"(\d+)", player_data['highest_ranking'])
                    player_data['highest_ranking'] = int(match.group(1)) if match else ranking

                save_player(player_data)
                players_scraped += 1
            except Exception as e:
                log.error(f"Error parsing WTA player row: {e}")
            except Exception as e:
                log.error(f"Error parsing WTA entry: {e}")

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
