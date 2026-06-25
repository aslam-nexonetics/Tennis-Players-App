import sys
from curl_cffi import requests
from bs4 import BeautifulSoup

def main():
    url = "https://www.ittf.com/wp-content/uploads/2026/06/2026_23_SEN_MS.html"
    print(f"Fetching {url} using curl_cffi...")
    try:
        response = requests.get(url, impersonate="chrome")
        print("Status Code:", response.status_code)
        print("Response Length:", len(response.text))
        
        soup = BeautifulSoup(response.text, "html.parser")
        table = soup.find("table")
        if table:
            print("Table found! Sample rows:")
            rows = table.find_all("tr")
            print(f"Total rows: {len(rows)}")
            for i, r in enumerate(rows[:10]):
                print(f"Row {i}: {[td.get_text(strip=True) for td in r.find_all(['td', 'th'])]}")
        else:
            print("No table found. Title of page:", soup.title.string if soup.title else "No title")
            print("Sample response HTML:")
            print(response.text[:2000])
    except Exception as e:
        print("Error fetching page:", e)

if __name__ == "__main__":
    main()
