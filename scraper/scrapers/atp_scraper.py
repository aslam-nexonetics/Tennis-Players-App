import random
import urllib.parse
import re
from datetime import datetime, timedelta
from scraper.base_scraper import BaseScraper
from scraper.utils.logger import log
from scraper.persistence import save_player
from scraper.scrapers.wiki_scraper import WikiScraper

WIKI_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/"

class ATPScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://en.wikipedia.org/wiki/ATP_rankings")
        self.wiki = WikiScraper()

    def scrape_rankings(self, limit=100):
        log.info(f"Scraping ATP rankings from official site (limit {limit})...")
        url = f"https://www.atptour.com/en/rankings/singles?rankRange=1-{limit}"
        soup = self.get_soup_playwright(url)
        if not soup:
            log.error("Failed to load ATP rankings via Playwright.")
            return

        players_scraped = 0
        # Target the rankings table
        table = soup.select_one("table.rankings-table")
        if not table:
            # Fallback if class changed
            table = soup.select_one("table")
        
        if not table:
            log.error("Could not find rankings table.")
            return

        rows = table.select("tbody tr")
        for row in rows:
            if players_scraped >= limit:
                break
            
            try:
                # Updated structure based on current ATP site:
                rank_cell = row.select_one("td.rank")
                player_link = row.select_one(".name a")
                
                if not rank_cell or not player_link: continue

                # Clean rank
                rank_text = rank_cell.text.strip().replace("T", "")
                if not rank_text.isdigit(): continue
                ranking = int(rank_text)

                # Get full name from the URL slug (e.g. /en/players/jannik-sinner/s0ag/overview -> jannik-sinner)
                player_url = player_link.get("href", "")
                name = ""
                if "/players/" in player_url:
                    parts = player_url.split("/")
                    try:
                        # The slug is usually the 4th part: ["", "en", "players", "jannik-sinner", ...]
                        slug = parts[parts.index("players") + 1]
                        name = " ".join(slug.split("-")).title()
                    except (ValueError, IndexError):
                        name = player_link.text.strip()
                else:
                    name = player_link.text.strip()

                # Clean name: remove excessive whitespace
                name = " ".join(name.split()).strip()
                # Aggressively remove trailing 3-letter country code if present
                name = re.sub(r'\s+[A-Z]{3}$', '', name)
                
                # Try to get country from the flag SVG
                country = "Unknown"
                flag_use = row.select_one("use")
                if flag_use and flag_use.get("href"):
                    country_match = flag_use.get("href").split("#flag-")
                    if len(country_match) > 1:
                        country = country_match[1].upper()
                
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
                    "gender": "M",
                    "image_url": wiki_data.get('image_url'),
                    "source": "ATP Tour / Wikipedia"
                }

                # Parse highest ranking if string
                if isinstance(player_data['highest_ranking'], str):
                    match = re.search(r"(\d+)", player_data['highest_ranking'])
                    player_data['highest_ranking'] = int(match.group(1)) if match else ranking

                save_player(player_data)
                players_scraped += 1
            except Exception as e:
                log.error(f"Error parsing ATP player row: {e}")
            except Exception as e:
                log.error(f"Error parsing ATP row: {e}")

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
