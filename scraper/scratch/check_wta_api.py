
import requests
from datetime import datetime

today = datetime.now().strftime("%Y-%m-%d")
url = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={today}&pageSize=1&page=0"
resp = requests.get(url)
print(resp.json())
