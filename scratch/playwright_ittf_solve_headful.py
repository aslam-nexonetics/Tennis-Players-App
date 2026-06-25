import time
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def main():
    url = "https://www.ittf.com/wp-content/uploads/2026/06/2026_23_SEN_MS.html"
    print(f"Navigating to {url} in HEADFUL mode...")
    with sync_playwright() as p:
        # Launch in headful mode using the active display
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        try:
            page.goto(url, wait_until="networkidle", timeout=60000)
            print("Page loaded. Title:", page.title())
            time.sleep(5) # Give it some time to settle
            
            content = page.content()
            soup = BeautifulSoup(content, "html.parser")
            print("Table tag found?", soup.find("table") is not None)
            if soup.find("table"):
                print("Table header:")
                th_elements = [th.text.strip() for th in soup.find("table").find_all("th")]
                print(th_elements)
                
                rows = soup.find("table").find_all("tr")
                print("Total rows:", len(rows))
                for i, r in enumerate(rows[:5]):
                    print(f"Row {i}: {[td.get_text(strip=True) for td in r.find_all(['td', 'th'])]}")
            else:
                print("No table found. Saving page source to scratch/headful_ittf_page.html")
                with open("scratch/headful_ittf_page.html", "w", encoding="utf-8") as f:
                    f.write(content)
        except Exception as e:
            print("Error occurred:", e)
        finally:
            browser.close()

if __name__ == "__main__":
    main()
