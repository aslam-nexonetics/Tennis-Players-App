import sys
import os
import time

project_root = "/home/nexonetics/nexonetics/tennis_app"
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, "backend"))
sys.path.append(os.path.join(project_root, "scraper"))

from scraper.base_scraper import BaseScraper

class ATPDateScraper(BaseScraper):
    def __init__(self):
        super().__init__("https://www.atptour.com/en/rankings/singles")

    def run(self):
        soup = self.get_soup_playwright(self.base_url)
        if not soup:
            print("Failed to get page soup")
            return
        
        # Look for select elements or dropdowns containing dateWeek
        selects = soup.find_all("select")
        print(f"Found {len(selects)} select elements")
        for i, s in enumerate(selects):
            print(f"Select {i}: id={s.get('id')}, class={s.get('class')}, name={s.get('name')}")
            # print some options
            options = s.find_all("option")
            print(f"  Options count: {len(options)}")
            for opt in options[:5]:
                print(f"    Option: value={opt.get('value')}, text={opt.text.strip()}")

        # Or maybe it's in a custom dropdown (like div/ul/li)
        # Let's search for any elements containing "2020" or similar
        print("Searching for custom elements containing '2020'")
        for el in soup.find_all(text=lambda text: text and "2020" in text)[:10]:
            parent = el.parent
            print(f"Text: {el.strip()}, Parent Tag: {parent.name}, Parent Class: {parent.get('class')}")

if __name__ == "__main__":
    scr = ATPDateScraper()
    scr.run()
