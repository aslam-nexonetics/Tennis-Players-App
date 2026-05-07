import requests
from bs4 import BeautifulSoup
from scraper.utils.logger import log
from scraper.utils.rate_limiter import RateLimiter
import time

class BaseScraper:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        })
        self.rate_limiter = RateLimiter()

    def get_soup(self, url: str, params=None):
        try:
            self.rate_limiter.wait()
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            return BeautifulSoup(response.text, "html.parser")
        except Exception as e:
            log.error(f"Error fetching {url}: {e}")
            return None

    def get_soup_playwright(self, url: str):
        try:
            from playwright.sync_api import sync_playwright
            self.rate_limiter.wait()
            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                # Use a specific user agent to look like a real browser
                context = browser.new_context(
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                )
                page = context.new_page()
                # Wait for domcontentloaded instead of networkidle to avoid timeouts on heavy sites
                page.goto(url, wait_until="domcontentloaded", timeout=60000)
                # Extra wait for dynamic content to render
                time.sleep(5)
                content = page.content()
                browser.close()
            return BeautifulSoup(content, "html.parser")
        except Exception as e:
            log.error(f"Error fetching {url} with playwright: {e}")
            return None

    def get_json(self, url: str, params=None):
        try:
            self.rate_limiter.wait()
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            log.error(f"Error fetching JSON from {url}: {e}")
            return None
