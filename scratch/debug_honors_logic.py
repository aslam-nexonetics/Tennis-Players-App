
import requests
import re
from bs4 import BeautifulSoup
import urllib.parse

def test_scrape_honors(team_name):
    wiki_name = f"{team_name} national football team"
    encoded = urllib.parse.quote(wiki_name.replace(" ", "_"))
    url = f"https://en.wikipedia.org/wiki/{encoded}"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    
    resp = requests.get(url, headers=headers)
    soup = BeautifulSoup(resp.text, 'html.parser')
    infobox = soup.select_one(".infobox")
    
    for row in infobox.select("tr"):
        header = row.select_one(".infobox-header")
        if header and "Copa América" in header.text:
            # Found Copa América header
            next_row = row.find_next_sibling("tr")
            while next_row and not next_row.select_one(".infobox-header"):
                label = next_row.select_one(".infobox-label")
                data = next_row.select_one(".infobox-data")
                if label and "Best result" in label.text and data:
                    text = data.get_text(separator=" ").strip()
                    print(f"DEBUG: {team_name} CC Text: '{text}'")
                    years = re.findall(r"\d{4}", text)
                    print(f"DEBUG: {team_name} CC Years: {years}")
                    
                    # Try to find "X times" pattern
                    times_match = re.search(r"(\d+)\s+times", text.lower())
                    if times_match:
                        print(f"DEBUG: Found times match: {times_match.group(1)}")
                next_row = next_row.find_next_sibling("tr")

if __name__ == "__main__":
    test_scrape_honors("Brazil")
    test_scrape_honors("Argentina")
