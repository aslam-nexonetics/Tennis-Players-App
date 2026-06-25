import os
import sys
from playwright.sync_api import sync_playwright

def main():
    url = "https://www.ittf.com/wp-content/uploads/2026/06/2026_23_SEN_MS.html"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
            page = context.new_page()
            response = page.goto(url, timeout=30000)
            print("Status:", response.status if response else "No response")
            content = page.content()
            print("Content length:", len(content))
            print("Sample content:")
            print(content[:1000])
            browser.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    main()
