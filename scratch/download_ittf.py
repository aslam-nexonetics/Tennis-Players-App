import time
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def scrape_url(url, output_filename):
    print(f"\nNavigating to {url}...")
    output_path = f"scratch/scraped_html/{output_filename}"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            
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
            print("Table tag found?", table_found)
            print("Page Title:", page.title())
            
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(content)
                
            if table_found:
                print(f"Saved page successfully to {output_path}")
                return True
            else:
                print(f"Saved page without table to {output_path}")
                return False
        except Exception as e:
            print("Error during scraping:", e)
            return False
        finally:
            browser.close()

if __name__ == "__main__":
    urls = {
        "2026_26_SEN_MS.html": "https://www.ittf.com/wp-content/uploads/2026/06/2026_26_SEN_MS.html",
        "2026_26_SEN_WS.html": "https://www.ittf.com/wp-content/uploads/2026/06/2026_26_SEN_WS.html"
    }
    for filename, url in urls.items():
        scrape_url(url, filename)
