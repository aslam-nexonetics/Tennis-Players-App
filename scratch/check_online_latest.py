import requests
import json
import re
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def check_atp():
    print("--- Checking ATP Online ---")
    url = "https://www.atptour.com/en/rankings/singles"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            page.wait_for_selector("select#dateWeek-filter", state="attached", timeout=15000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            select = soup.find("select", id="dateWeek-filter")
            if select:
                options = select.find_all("option")
                dates = []
                for opt in options:
                    val = opt.get("value")
                    text = opt.text.strip()
                    if val and re.match(r"^\d{4}-\d{2}-\d{2}$", val):
                        dates.append(val)
                    elif text and re.match(r"^\d{4}\.\d{2}\.\d{2}$", text):
                        dates.append(text.replace(".", "-"))
                print("ATP Latest 5 Available Dates on site:", dates[:5])
            browser.close()
    except Exception as e:
        print("ATP Check Error:", e)

def check_wta():
    print("\n--- Checking WTA Online ---")
    url = "https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&pageSize=5"
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    try:
        res = requests.get(url, headers=headers, timeout=15)
        if res.status_code == 200:
            data = res.json()
            print("WTA API returned top 5 players for current rankings.")
            if isinstance(data, list) and len(data) > 0:
                print("Sample WTA player rank 1:", data[0].get("player", {}).get("player", {}).get("fullName"), "| Rank:", data[0].get("rank"))
        
        # Also check page html for ranking date string
        page_res = requests.get("https://www.wtatennis.com/rankings/singles", headers=headers, timeout=15)
        soup = BeautifulSoup(page_res.text, "html.parser")
        date_el = soup.select_one(".rankings__date") or soup.select_one(".date") or soup.find(text=re.compile(r"As of|2026"))
        if date_el:
            print("WTA Date Text on Page:", date_el if isinstance(date_el, str) else date_el.text.strip())
    except Exception as e:
        print("WTA Check Error:", e)

def check_ittf():
    print("\n--- Checking ITTF / WTT Online ---")
    # Check ITTF rankings API or WTT pages
    # ITTF ranking lists API: https://rankings.ittf.com/ or WTT API
    # Let's try ITTF API endpoint or WTT endpoint
    urls = [
        "https://www.worldtabletennis.com/allplayersranking",
        "https://rankings.ittf.com/"
    ]
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    try:
        res = requests.get("https://rankings.ittf.com/", headers=headers, timeout=15)
        print("ITTF site status code:", res.status_code)
    except Exception as e:
        print("ITTF Check Error:", e)

if __name__ == "__main__":
    check_atp()
    check_wta()
    check_ittf()
