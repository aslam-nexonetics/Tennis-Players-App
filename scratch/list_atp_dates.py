import re
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def main():
    url = "https://www.atptour.com/en/rankings/singles?dateWeek=Current+Week"
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        page = context.new_page()
        page.goto(url, wait_until="domcontentloaded", timeout=30000)
        page.wait_for_selector("select#dateWeek-filter", timeout=15000)
        content = page.content()
        soup = BeautifulSoup(content, "html.parser")
        select = soup.find("select", id="dateWeek-filter")
        if select:
            options = select.find_all("option")
            print(f"Total options: {len(options)}")
            for opt in options[:10]:
                print(f"Option text: {opt.text.strip()}, value: {opt.get('value')}")
        else:
            print("Dropdown not found.")
        browser.close()

if __name__ == "__main__":
    main()
