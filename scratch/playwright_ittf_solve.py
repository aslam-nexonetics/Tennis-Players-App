import time
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def main():
    url = "https://www.ittf.com/wp-content/uploads/2026/06/2026_23_SEN_MS.html"
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        # Try a real browser profile or context
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        print("Navigating...")
        page.goto(url, wait_until="load", timeout=60000)
        print("Initial Title:", page.title())
        
        # Wait to see if Cloudflare challenge page is there and if we can bypass
        for i in range(15):
            print(f"Waiting {i+1}s, Title: {page.title()}")
            time.sleep(1)
            
        content = page.content()
        soup = BeautifulSoup(content, "html.parser")
        print("Table tag found?", soup.find("table") is not None)
        if soup.find("table"):
            print("First table content snippet:")
            print(str(soup.find("table"))[:1000])
        else:
            print("No table found. Saving HTML page to scratch/ittf_page.html...")
            with open("scratch/ittf_page.html", "w", encoding="utf-8") as f:
                f.write(content)
        browser.close()

if __name__ == "__main__":
    main()
