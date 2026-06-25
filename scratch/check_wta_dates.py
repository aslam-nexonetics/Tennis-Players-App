import requests

def main():
    dates = ["2026-06-15", "2026-06-22"]
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    for d in dates:
        url = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={d}&pageSize=5&page=0"
        try:
            res = requests.get(url, headers=headers, timeout=15)
            print(f"Date {d}: status {res.status_code}, data length: {len(res.json()) if res.status_code == 200 else 'N/A'}")
            if res.status_code == 200 and len(res.json()) > 0:
                print("  Sample:", res.json()[0].get('player', {}).get('firstName'), res.json()[0].get('player', {}).get('lastName'))
        except Exception as e:
            print(f"Date {d} error: {e}")

if __name__ == "__main__":
    main()
