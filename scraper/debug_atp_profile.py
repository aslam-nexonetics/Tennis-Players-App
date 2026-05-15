import sys
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def debug_atp_profile(url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        content = page.content()
        browser.close()
        
    soup = BeautifulSoup(content, "html.parser")
    items = soup.select(".pd_left li, .pd_right li")
    for item in items:
        label = item.select_one("span:nth-child(1)")
        value = item.select_one("span:nth-child(2)")
        if label and value:
            print(f"Label: {label.text.strip()} | Value: {value.text.strip()}")

if __name__ == "__main__":
    debug_atp_profile("https://www.atptour.com/en/players/jannik-sinner/s0au/overview")
