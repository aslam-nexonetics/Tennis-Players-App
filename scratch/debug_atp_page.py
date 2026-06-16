import sys
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

url = "https://www.atptour.com/en/rankings/singles?dateWeek=2020-01-13&rankRange=0-100"
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    page = context.new_page()
    page.goto(url, wait_until="networkidle", timeout=60000)
    print(f"Current page URL: {page.url}")
    print(f"Title: {page.title()}")
    content = page.content()
    soup = BeautifulSoup(content, "html.parser")
    table = soup.select_one("table.rankings-table") or soup.select_one("table")
    if table:
        print("Table tag found:", table.name, "with class:", table.get("class"))
        rows = table.select("tbody tr")
        print(f"Number of rows: {len(rows)}")
    else:
        print("Table not found. Printing some elements:")
        for select in soup.find_all("select")[:3]:
            print(f"Select ID: {select.get('id')}, selected: {[opt.text.strip() for opt in select.find_all('option') if opt.get('selected')]}")
    browser.close()
