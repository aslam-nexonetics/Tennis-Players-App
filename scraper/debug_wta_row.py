from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup

url = "https://www.wtatennis.com/rankings/singles"
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    page.goto(url, wait_until="networkidle")
    content = page.content()
    browser.close()

soup = BeautifulSoup(content, "html.parser")
table = soup.select_one("table")
if table:
    rows = table.select("tbody tr")
    if rows:
        row = rows[0]
        print("Row HTML structure:")
        print(row.prettify()[:1000])
