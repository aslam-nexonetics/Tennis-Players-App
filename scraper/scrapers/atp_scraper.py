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

    def scrape_rankings(self, limit=1500):
        log.info(f"Scraping ATP rankings from official site (limit {limit})...")
        
        players_scraped = 0
        # ATP uses segments of 100 for rankRange (e.g. 1-100, 101-200)
        # We'll fetch segments until we reach the limit
        for start in range(0, limit, 100):
            if players_scraped >= limit:
                break
            
            range_str = f"{start + 1}-{start + 100}"
            url = f"https://www.atptour.com/en/rankings/singles?rankRange={range_str}"
            log.info(f"Fetching ATP rankings segment: {range_str}")
            
            soup = self.get_soup_playwright(url)
            if not soup:
                log.error(f"Failed to load ATP rankings segment {range_str}")
                continue

            table = soup.select_one("table.rankings-table") or soup.select_one("table")
            if not table:
                log.error(f"Could not find rankings table in segment {range_str}")
                continue

            rows = table.select("tbody tr")
            for row in rows:
                if players_scraped >= limit:
                    break
                
                try:
                    # Target rank and player link
                    rank_cell = row.select_one("td.rank")
                    player_link = row.select_one(".name a")
                    
                    if not rank_cell or not player_link: continue

                    # Clean rank
                    rank_text = rank_cell.text.strip().replace("T", "")
                    if not rank_text.isdigit(): continue
                    ranking = int(rank_text)

                    # Get name and profile URL
                    player_url_path = player_link.get("href", "")
                    raw_name = player_link.text.strip()
                    
                    # Clean name: remove excessive whitespace and trailing country codes
                    name = " ".join(raw_name.split()).strip()
                    name = re.sub(r'\s+[A-Z]{3}$', '', name)
                    
                    # Use name from slug as it's often more complete than the ranking table
                    if "/players/" in player_url_path:
                        parts = player_url_path.split("/")
                        try:
                            slug = parts[parts.index("players") + 1]
                            name_from_slug = " ".join(slug.split("-")).title()
                            # Prefer slug name if the table name has dots (likely abbreviated) 
                            # or is shorter than the slug name
                            if "." in name or len(name) < len(name_from_slug):
                                name = name_from_slug
                                log.info(f"Using full name from slug: {name}")
                        except (ValueError, IndexError):
                            pass

                    # Try to get country from the flag SVG
                    country = "Unknown"
                    flag_use = row.select_one("use")
                    if flag_use and flag_use.get("href"):
                        country_match = flag_use.get("href").split("#flag-")
                        if len(country_match) > 1:
                            country = country_match[1].upper()
                    
                    log.info(f"Found {name} (Rank {ranking}). Enriching...")
                    
                    # Initial data
                    player_data = {
                        "name": name,
                        "ranking": ranking,
                        "gender": "M",
                        "country": country,
                        "source": "ATP Tour"
                    }

                    # Enrichment Strategy:
                    # 1. Try ATP Profile directly for accuracy (especially for specific requests)
                    # 2. Fallback to Wikipedia
                    full_profile_url = f"https://www.atptour.com{player_url_path}" if player_url_path.startswith("/") else player_url_path
                    
                    # To keep pictures and full profiles for a good range, we enrich top 1000 
                    # OR for the specifically requested players: Svyatoslav Gulin and Denis Klok
                    priority_players = ["Gulin", "Klok", "Svyatoslav", "Denis"]
                    if ranking <= 1000 or any(p.lower() in name.lower() for p in priority_players):
                        self.enrich_from_atp(full_profile_url, player_data)
                    
                    # If we still lack key data, try Wikipedia (only for top 1000 to keep it fast)
                    if ranking <= 1000 and (not player_data.get("height") or not player_data.get("birth_date")):
                        wiki_data = self.wiki.enrich_player(name)
                        if wiki_data:
                            for key, val in wiki_data.items():
                                if not player_data.get(key):
                                    player_data[key] = val

                    # Final sanitization
                    if not player_data.get("highest_ranking"):
                        player_data["highest_ranking"] = ranking
                    
                    if isinstance(player_data.get('highest_ranking'), str):
                        match = re.search(r"(\d+)", str(player_data['highest_ranking']))
                        player_data['highest_ranking'] = int(match.group(1)) if match else ranking

                    save_player(player_data)
                    players_scraped += 1
                except Exception as e:
                    log.error(f"Error parsing ATP player row: {e}")

    def enrich_from_atp(self, url, player_data):
        log.info(f"Enriching {player_data['name']} from ATP profile...")
        soup = self.get_soup_playwright(url)
        if not soup: return

        try:
            # Image
            img = soup.select_one(".atp_player-profile-hero-image img")
            if img and img.get("src"):
                player_data["image_url"] = img.get("src")
                if player_data["image_url"].startswith("/"):
                    player_data["image_url"] = "https://www.atptour.com" + player_data["image_url"]

            # Stats list
            # Selectors based on browser investigation
            age_span = soup.select_one(".pd_left li:nth-child(1) span:nth-child(2)")
            weight_span = soup.select_one(".pd_left li:nth-child(2) span:nth-child(2)")
            height_span = soup.select_one(".pd_left li:nth-child(3) span:nth-child(2)")
            turned_pro_span = soup.select_one(".pd_left li:nth-child(4) span:nth-child(2)")
            plays_span = soup.select_one(".pd_right li:nth-child(3) span:nth-child(2)")
            prize_money_span = soup.select_one(".atp_player-profile-header-stats-row:nth-child(2) .prize_money")

            # Full Name from profile
            name_div = soup.select_one(".atp_player-profile-hero-name")
            if name_div:
                first_name = name_div.select_one(".first-name")
                last_name = name_div.select_one(".last-name")
                if first_name and last_name:
                    full_name = f"{first_name.text.strip()} {last_name.text.strip()}"
                    player_data["name"] = full_name
                elif name_div.text.strip():
                    player_data["name"] = name_div.text.strip()

            if age_span:
                # Format: "23 (2002/12/04)"
                text = age_span.text.strip()
                date_match = re.search(r"\((\d{4}/\d{2}/\d{2})\)", text)
                if date_match:
                    from datetime import datetime
                    try:
                        player_data["birth_date"] = datetime.strptime(date_match.group(1), "%Y/%m/%d").date()
                    except: pass

            if weight_span: player_data["weight"] = weight_span.text.strip()
            if height_span: player_data["height"] = height_span.text.strip()
            if turned_pro_span and turned_pro_span.text.strip(): 
                player_data["turned_pro"] = turned_pro_span.text.strip()
            if plays_span: player_data["playing_style"] = plays_span.text.strip()
            if prize_money_span: player_data["prize_money"] = prize_money_span.text.strip()

        except Exception as e:
            log.error(f"Error enriching from ATP: {e}")


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
