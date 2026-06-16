import sys
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

url = "https://www.atptour.com/en/rankings/singles?dateWeek=2020-01-06&rankRange=0-100"
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    page = context.new_page()
    page.goto(url, wait_until="domcontentloaded", timeout=60000)
    page.wait_for_selector("table", state="attached", timeout=10000)
    content = page.content()
    soup = BeautifulSoup(content, "html.parser")
    table = soup.select_one("table")
    if table:
        rows = table.select("tbody tr")
        print(f"Found {len(rows)} rows.")
        if len(rows) > 0:
            first_row = rows[0]
            # print HTML of the first row
            print("First row HTML snippet:")
            print(first_row.prettify()[:1500])
    browser.close()
