
import requests
import re
from bs4 import BeautifulSoup
import urllib.parse

def test_headers(team_name):
    wiki_name = f"{team_name} national football team"
    encoded = urllib.parse.quote(wiki_name.replace(" ", "_"))
    url = f"https://en.wikipedia.org/wiki/{encoded}"
    headers = {"User-Agent": "Mozilla/5.0"}
    resp = requests.get(url, headers=headers)
    soup = BeautifulSoup(resp.text, 'html.parser')
    infobox = soup.select_one(".infobox")
    if not infobox: return
    for row in infobox.select("tr"):
        header = row.select_one(".infobox-header")
        if header:
            print(f"Header: '{header.text.strip()}'")

if __name__ == "__main__":
    test_headers("Mexico")
    test_headers("USA")
