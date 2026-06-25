import re
import requests
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

def get_current_atp_date():
    url = "https://www.atptour.com/en/rankings/singles?dateWeek=Current+Week"
    try:
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
                # Find the option with selected attribute, or the first option if none is selected
                options = select.find_all("option")
                # Filter out "Current Week" and match YYYY-MM-DD
                for opt in options:
                    val = opt.get("value")
                    if val and re.match(r"^\d{4}-\d{2}-\d{2}$", val):
                        print(f"First valid ATP date in dropdown: {val} (selected={opt.has_attr('selected') or opt.get('selected')})")
                        return val
            browser.close()
    except Exception as e:
        print("Error getting ATP date:", e)
    return None

def get_current_wta_date():
    # We can fetch the list of dates from WTA website or just try to get the current date
    # Let's see if there is an endpoint or if we can extract it from the api request.
    # WTA rankings are updated on Mondays. Let's see what is the date of today or this Monday.
    # We can also fetch the html from wtatennis.com/rankings/singles and see the date displayed.
    url = "https://www.wtatennis.com/rankings/singles"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        soup = BeautifulSoup(response.text, "html.parser")
        # Let's search for any date in the page
        # Often there is a dropdown or a date selector or a text like "As of June 22, 2026"
        print("WTA page title:", soup.title.text if soup.title else "No title")
        # Let's find some date elements
        date_el = soup.select_one(".rankings__date") or soup.select_one(".date")
        if date_el:
            print("WTA date element text:", date_el.text.strip())
        
        # Let's also check what dates are valid via a sample api call or checking dropdowns
        # WTA api has at option. What if we do a GET to the wta players API with a very future date, or no date?
        # If no 'at' parameter is passed, does it return the current rankings?
        # Let's test that:
        url_no_date = "https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&pageSize=5"
        res = requests.get(url_no_date, headers=headers, timeout=15)
        if res.status_code == 200:
            print("WTA API without 'at' parameter returns 200, length:", len(res.json()))
            # If so, the WTA API handles "current" by default when 'at' is omitted or we can find it
    except Exception as e:
        print("Error getting WTA date:", e)

def main():
    print("Fetching current dates from web...")
    atp_date = get_current_atp_date()
    get_current_wta_date()

if __name__ == "__main__":
    main()
