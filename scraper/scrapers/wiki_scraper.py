from scraper.base_scraper import BaseScraper
from scraper.utils.logger import log
import urllib.parse

class WikiScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://en.wikipedia.org/api/rest_v1/page/summary/")

    def enrich_player(self, player_name: str):
        log.info(f"Enriching data for {player_name} via Wikipedia...")
        encoded_name = urllib.parse.quote(player_name.replace(" ", "_"))
        url = f"{self.base_url}{encoded_name}"
        
        data = self.get_json(url)
        if not data:
            return None

        enriched_data = {}
        if 'extract' in data:
            # We could parse the extract for bio data if not structured
            log.debug(f"Wiki summary found for {player_name}")
            
        if 'thumbnail' in data:
            enriched_data['image_url'] = data['thumbnail'].get('source')

        # For more complex data (height, birth date), we'd need to scrape the infobox
        # Using the actual page HTML
        page_url = data.get('content_urls', {}).get('desktop', {}).get('page')
        if page_url:
            self.scrape_infobox(page_url, enriched_data)
            
        return enriched_data

    def scrape_infobox(self, url, enriched_data):
        import re
        from datetime import datetime
        soup = self.get_soup(url)
        if not soup: return

        infobox = soup.select_one(".infobox")
        if not infobox: return

        # Simple mapping for common infobox labels
        mappings = {
            "Born": "birth_date",
            "Height": "height",
            "Weight": "weight",
            "Plays": "playing_style"
        }

        for row in infobox.select("tr"):
            label = row.select_one(".infobox-label")
            data_cell = row.select_one(".infobox-data")
            if label and data_cell:
                label_text = label.text.strip()
                for key, field in mappings.items():
                    if key in label_text:
                        raw_val = data_cell.text.strip()
                        if field == 'birth_date':
                            match = re.search(r"(\d{4}-\d{2}-\d{2})", raw_val)
                            if match:
                                try:
                                    enriched_data[field] = datetime.strptime(match.group(1), "%Y-%m-%d").date()
                                except ValueError:
                                    pass
                        else:
                            enriched_data[field] = raw_val
