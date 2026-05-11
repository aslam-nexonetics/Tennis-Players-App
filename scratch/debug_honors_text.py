
import requests
import re
from bs4 import BeautifulSoup
import urllib.parse

def test_scrape_honors(team_name, category="men"):
    wiki_name = f"{team_name} national football team"
    encoded = urllib.parse.quote(wiki_name.replace(" ", "_"))
    url = f"https://en.wikipedia.org/wiki/{encoded}"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    resp = requests.get(url, headers=headers)
    soup = BeautifulSoup(resp.text, 'html.parser')
    infobox = soup.select_one(".infobox")
    
    world_cup_titles = 0
    continental_titles = 0
    
    current_comp = None
    for row in infobox.select("tr"):
        header = row.select_one(".infobox-header")
        if header:
            header_text = header.text.strip()
            if "World Cup" in header_text:
                current_comp = "WC"
            elif any(cup in header_text for cup in ["European Championship", "Copa América", "Africa Cup of Nations", "Asian Cup", "Gold Cup", "Nations Cup"]):
                current_comp = "CC"
            else:
                current_comp = None
            continue
        
        if current_comp:
            label = row.select_one(".infobox-label")
            data = row.select_one(".infobox-data")
            if label and "Best result" in label.text and data:
                text = data.get_text(separator=" ").strip()
                print(f"Parsing {team_name} {current_comp}: '{text}'")
                if "Winners" in text or "Champions" in text:
                    years = re.findall(r"\d{4}", text)
                    count = len(years) if years else (1 if "once" in text.lower() else 1)
                    if current_comp == "WC": world_cup_titles = count
                    else: continental_titles = count
                current_comp = None

if __name__ == "__main__":
    test_scrape_honors("Brazil")
    test_scrape_honors("Argentina")
