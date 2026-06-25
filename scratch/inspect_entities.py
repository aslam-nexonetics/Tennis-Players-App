import requests
import json

headers = {
    "User-Agent": "TableTennisPlayerDatabaseScraper/1.0 (contact: info@example.com)"
}

def inspect_entity(entity_id):
    print(f"\n=== Inspecting {entity_id} ===")
    url = f"https://www.wikidata.org/wiki/Special:EntityData/{entity_id}.json"
    r = requests.get(url, headers=headers)
    entity = r.json().get("entities", {}).get(entity_id, {})
    
    # Label
    label = entity.get("labels", {}).get("en", {}).get("value", "")
    print(f"Label (en): {label}")
    
    # Description
    desc = entity.get("descriptions", {}).get("en", {}).get("value", "")
    print(f"Description (en): {desc}")
    
    # Claims
    claims = entity.get("claims", {})
    
    # Instance of (P31)
    p31 = claims.get("P31", [])
    p31_ids = [c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id") for c in p31]
    print(f"P31 (instance of): {p31_ids}")
    
    # Occupation (P106)
    p106 = claims.get("P106", [])
    p106_ids = [c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id") for c in p106]
    print(f"P106 (occupation): {p106_ids}")
    
    # Date of birth (P569)
    p569 = claims.get("P569", [])
    p569_vals = [c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("time") for c in p569]
    print(f"P569 (birth date): {p569_vals}")

inspect_entity("Q107622517")
inspect_entity("Q98211310")
