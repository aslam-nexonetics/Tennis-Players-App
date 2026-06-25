import requests
headers = {"User-Agent": "TableTennisPlayerDatabaseScraper/1.0"}
url = "https://www.wikidata.org/wiki/Special:EntityData/Q13382519.json"
r = requests.get(url, headers=headers)
print(r.json().get("entities", {}).get("Q13382519", {}).get("labels", {}).get("en", {}).get("value"))
