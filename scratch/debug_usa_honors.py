
import requests
import re
from bs4 import BeautifulSoup
import urllib.parse

def test_usa():
    wiki_name = "United States national soccer team"
    encoded = urllib.parse.quote(wiki_name.replace(" ", "_"))
    url = f"https://en.wikipedia.org/wiki/{encoded}"
    headers = {"User-Agent": "Mozilla/5.0"}
    resp = requests.get(url, headers=headers)
    soup = BeautifulSoup(resp.text, 'html.parser')
    infobox = soup.select_one(".infobox")
    
    cc_pattern = r"CONCACAF (Championship|Gold Cup)"
    
    current_comp = None
    for row in infobox.select("tr"):
        header = row.select_one(".infobox-header")
        if header:
            header_text = header.text.strip()
            if re.search(cc_pattern, header_text, re.IGNORECASE):
                print(f"Header Matched: {header_text}")
                current_comp = "CC"
            else:
                current_comp = None
            continue
        
        if current_comp == "CC":
            label = row.select_one(".infobox-label")
            data = row.select_one(".infobox-data")
            if label and "Best result" in label.text and data:
                text = data.get_text(separator=" ").strip()
                print(f"Text: {text}")
                if "Winners" in text or "Champions" in text:
                    years = re.findall(r"\d{4}", text)
                    print(f"Years: {years}")

if __name__ == "__main__":
    test_usa()
