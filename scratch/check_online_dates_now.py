import urllib.request
import json
import re
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def check_atp_dates():
    print("=== Checking ATP Online Dates ===")
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
                print("ATP Latest Available Dates on website:", dates[:10])
                # Also check current displayed top 3
                rows = soup.select("table.rankings-table tbody tr") or soup.select("table tbody tr")
                print(f"ATP rows found: {len(rows)}")
                for r in rows[:3]:
                    rank = r.select_one(".rank")
                    name = r.select_one(".name")
                    if rank and name:
                        print(f"  Rank {rank.text.strip()}: {name.text.strip()}")
            browser.close()
    except Exception as e:
        print("ATP Error:", e)

def check_wta_dates():
    print("\n=== Checking WTA Online Dates ===")
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    # Check without 'at' param to get current week
    url = "https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&pageSize=5"
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print("WTA API response item count:", len(data))
            if data:
                p1 = data[0]
                rank = p1.get('ranking')
                p_info = p1.get('player', {})
                name = f"{p_info.get('firstName')} {p_info.get('lastName')}"
                print(f"  WTA Rank {rank}: {name}")
    except Exception as e:
        print("WTA API Error:", e)

    # Check WTA site for text date
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            page.goto("https://www.wtatennis.com/rankings/singles", wait_until="domcontentloaded", timeout=30000)
            page.wait_for_selector(".rankings-table, table", timeout=15000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            date_el = soup.find(text=re.compile(r"As of|2026|August", re.IGNORECASE))
            if date_el:
                print("  WTA Date string on page:", date_el.parent.text.strip() if date_el.parent else date_el.strip())
            browser.close()
    except Exception as e:
        print("WTA Page Error:", e)

def check_wtt_dates():
    print("\n=== Checking WTT / ITTF Online Dates ===")
    url = "https://www.worldtabletennis.com/allplayersranking"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            page.wait_for_selector("table, tr.cursor_move", timeout=15000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            rows = soup.select("tr.cursor_move") or soup.select("table tbody tr")
            print(f"WTT rows found: {len(rows)}")
            for r in rows[:3]:
                rank = r.select_one(".player-rank") or r.select_one("td:nth-child(1)")
                name = r.select_one(".player_name") or r.select_one("td:nth-child(2)")
                if rank and name:
                    print(f"  WTT Rank {rank.text.strip()}: {name.text.strip()}")
            
            # Check week or date info on page
            week_el = soup.find(text=re.compile(r"Week|2026|August|As of", re.IGNORECASE))
            if week_el:
                print("  WTT Week/Date info:", week_el.parent.text.strip() if week_el.parent else week_el.strip())
            browser.close()
    except Exception as e:
        print("WTT Error:", e)

if __name__ == "__main__":
    check_atp_dates()
    check_wta_dates()
    check_wtt_dates()
