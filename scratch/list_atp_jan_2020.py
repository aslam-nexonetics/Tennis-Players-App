import sys
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

url = "https://www.atptour.com/en/rankings/singles"
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    page = context.new_page()
    page.goto(url, wait_until="domcontentloaded", timeout=60000)
    # wait a bit for option loading
    page.wait_for_selector("select#dateWeek-filter", timeout=10000)
    content = page.content()
    soup = BeautifulSoup(content, "html.parser")
    select = soup.find("select", id="dateWeek-filter")
    if select:
        options = select.find_all("option")
        all_dates = [opt.get("value") for opt in options if opt.get("value")]
        print(f"Total dates found: {len(all_dates)}")
        dates_2020 = [d for d in all_dates if d.startswith("2020-")]
        print(f"Total dates in 2020: {len(dates_2020)}")
        print("Dates in 2020:")
        print(dates_2020)
    else:
        print("dateWeek-filter select not found")
    browser.close()
