from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup

url = "https://www.atptour.com/en/rankings/singles?rankRange=1-100"
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    print(f"Navigating to {url}")
    page.goto(url, wait_until="networkidle")
    content = page.content()
    browser.close()

soup = BeautifulSoup(content, "html.parser")
table = soup.select_one("table.rankings-table")
if not table:
    table = soup.select_one("table")

if table:
    print(f"Found table. Classes: {table.get('class')}")
    rows = table.select("tbody tr")
    print(f"Found {len(rows)} rows in tbody")
    if rows:
        print(f"First row content snippet: {rows[0].text.strip()[:100]}")
else:
    print("No table found")
