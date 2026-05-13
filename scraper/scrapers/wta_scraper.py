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
                    player_id = player_info.get('id')
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
                    
                    player_data = {
                        "name": name,
                        "ranking": ranking,
                        "birth_date": birth_date,
                        "country": country,
                        "gender": "F",
                        "source": "WTA Tour Official"
                    }

                    # Enrich from Official Profile if ID available
                    if player_id and ranking <= 500:
                        slug = name.lower().replace(" ", "-")
                        profile_url = f"https://www.wtatennis.com/players/{player_id}/{slug}"
                        self.enrich_from_wta(profile_url, player_data)

                    # Fallback to Wikipedia for additional info or missing fields
                    if ranking <= 1000 and (not player_data.get("height") or not player_data.get("wins")):
                        wiki_data = self.wiki.enrich_player(name)
                        if wiki_data:
                            for key, val in wiki_data.items():
                                if not player_data.get(key):
                                    player_data[key] = val

                    # Parse highest ranking if string
                    if not player_data.get("highest_ranking"):
                        player_data["highest_ranking"] = ranking
                    
                    if isinstance(player_data.get('highest_ranking'), str):
                        match = re.search(r"(\d+)", str(player_data['highest_ranking']))
                        player_data['highest_ranking'] = int(match.group(1)) if match else ranking

                    save_player(player_data)
                    players_scraped += 1
                except Exception as e:
                    log.error(f"Error parsing WTA API item: {e}")

            page += 1
            if len(data) < page_size:
                break

    def enrich_from_wta(self, url, player_data):
        log.info(f"Enriching {player_data['name']} from WTA profile...")
        soup = self.get_soup_playwright(url)
        if not soup: return

        try:
            # Image
            img = soup.select_one(".player-headshot__photo img")
            if img and img.get("src"):
                wta_image_url = img.get("src")
                # Try to get a Wikipedia image for better compatibility with our proxy
                wiki_image = self._fetch_wiki_image(player_data['name'])
                if wiki_image:
                    player_data["image_url"] = wiki_image
                else:
                    player_data["image_url"] = wta_image_url

            # Stats (Highest Rank, Win/Loss)
            # These are in blocks with labels
            stat_blocks = soup.select(".stat-block")
            for block in stat_blocks:
                label_el = block.select_one(".stat-block__label")
                if not label_el: continue
                label = label_el.text.strip().lower()

                if "highest singles rank" in label:
                    rank_el = block.select_one(".stat-block__rank-number")
                    date_el = block.select_one(".stat-block__rank-date")
                    if rank_el:
                        try:
                            player_data["highest_ranking"] = int(rank_el.text.strip())
                        except: pass
                    if date_el:
                        # Format: "04 Apr 22" or similar
                        try:
                            player_data["highest_ranking_date"] = datetime.strptime(date_el.text.strip(), "%d %b %y").date()
                        except: pass
                
                elif "won / lost" in label:
                    val_el = block.select_one(".stat-block__stat-value")
                    if val_el:
                        # Format: "418 / 100"
                        parts = val_el.text.split("/")
                        if len(parts) == 2:
                            try:
                                player_data["wins"] = int(parts[0].strip())
                                player_data["losses"] = int(parts[1].strip())
                            except: pass

            # Physical info (Height, Turned Pro)
            # These are often in a different section or simple text
            # Usually in .player-profile__info-list
            height_el = soup.select_one(".player-profile__info-item:nth-child(2) .player-profile__info-value")
            if height_el and "m" in height_el.text:
                player_data["height"] = height_el.text.strip()

        except Exception as e:
            log.error(f"Error enriching from WTA: {e}")

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
