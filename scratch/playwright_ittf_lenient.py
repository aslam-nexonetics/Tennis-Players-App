import time
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def scrape_url(url, output_filename):
    print(f"\nNavigating to {url}...")
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(headless=False, channel="chrome", args=["--disable-blink-features=AutomationControlled"])
        except Exception:
            browser = p.chromium.launch(headless=False, args=["--disable-blink-features=AutomationControlled"])
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        try:
            # Navigate with domcontentloaded and shorter timeout
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=25000)
            except Exception as e:
                print(f"Navigation timed out or had error: {e}, attempting to read page source anyway...")
            
            # Wait up to 10 seconds for table to appear
            table_found = False
            for _ in range(10):
                content = page.content()
                soup = BeautifulSoup(content, "html.parser")
                if soup.find("table"):
                    table_found = True
                    break
                time.sleep(1)
                
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            print("Table tag found?", table_found)
            print("Page Title:", page.title())
            
            # Save page source to debug
            os.makedirs("scratch/scraped_html", exist_ok=True)
            with open(f"scratch/scraped_html/{output_filename}", "w", encoding="utf-8") as f:
                f.write(content)
                
            if table_found:
                print(f"Saved page successfully with table to scratch/scraped_html/{output_filename}")
            else:
                print(f"Saved page without table to scratch/scraped_html/{output_filename} (Title: {page.title()})")
        except Exception as e:
            print("Error during scraping:", e)
        finally:
            browser.close()

if __name__ == "__main__":
    scrape_url("https://www.ittf.com/wp-content/uploads/2026/06/2026_23_SEN_MS.html", "2026_23_SEN_MS.html")
