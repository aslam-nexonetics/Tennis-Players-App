from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import re

def check_wtt_date():
    url = "https://www.worldtabletennis.com/allplayersranking?selectedTab=MEN%27S%20SINGLES&Age=SENIOR&Rank=1"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            page.goto(url, wait_until="networkidle", timeout=45000)
            page.wait_for_timeout(3000)
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            
            # Find any date or week dropdown/text
            week_el = soup.select_one(".ranking_week") or soup.select_one(".week_select") or soup.select_one("select")
            text_nodes = soup.find_all(text=re.compile(r"Week|2026|July|August", re.IGNORECASE))
            
            print("WTT Page Title:", soup.title.text if soup.title else "No title")
            print("Found text nodes related to week/date:")
            for t in text_nodes[:10]:
                val = t.strip()
                if len(val) > 0 and len(val) < 100:
                    print(" -", val)
            
            rows = soup.select("tr.cursor_move") or soup.select("table tbody tr")
            print(f"Total ranking rows on WTT main page: {len(rows)}")
            if len(rows) > 0:
                rank1 = rows[0].text.strip()
                print("Rank #1 row snippet:", " | ".join(rank1.split()))

            browser.close()
    except Exception as e:
        print("Error checking WTT:", e)

if __name__ == "__main__":
    check_wtt_date()
