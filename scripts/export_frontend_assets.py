#!/usr/bin/env python3
"""
Export frontend JSON assets by querying the local backend API.

Usage:
  backend/venv/bin/python scripts/export_frontend_assets.py --base http://localhost:8000

This script writes files into `frontend/assets/data/`:
  - players.json
  - player_histories.json
  - tt_players.json
  - tt_player_histories.json
  - football_national_teams.json
  - basketball_clubs.json

The script paginates through list endpoints and fetches individual details
to collect ranking histories so the frontend can be used fully offline.
"""
import os
import sys
import json
import argparse
from urllib.parse import urljoin

try:
    import requests
except Exception:
    print('Please install requests (pip install requests) in your Python environment')
    raise

OUT_DIR = os.path.join('frontend', 'assets', 'data')
os.makedirs(OUT_DIR, exist_ok=True)

def paged_fetch(session, url, params=None, page_size=50, timeout=120):
    page = 1
    all_items = []
    while True:
        p = dict(params or {})
        p.update({'page': page, 'size': page_size})
        r = session.get(url, params=p, timeout=timeout)
        r.raise_for_status()
        data = r.json()
        items = data.get('items') if isinstance(data, dict) and 'items' in data else data
        if not items:
            break
        all_items.extend(items)
        # If we received fewer than page_size, we're done
        if isinstance(items, list) and len(items) < page_size:
            break
        page += 1
    return all_items

def write_json(path, obj):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
    print('Wrote', path)

def export_players(base_url, session):
    url = urljoin(base_url, '/players/')
    items = paged_fetch(session, url)
    write_json(os.path.join(OUT_DIR, 'players.json'), items)

    # Export individual histories
    histories = {}
    for p in items:
        pid = p.get('id')
        if not pid:
            continue
        r = session.get(urljoin(base_url, f'/players/{pid}'), timeout=30)
        if r.status_code != 200:
            continue
        detail = r.json()
        hist = detail.get('ranking_history')
        if hist:
            histories[str(pid)] = hist
    write_json(os.path.join(OUT_DIR, 'player_histories.json'), histories)

def export_tt_players(base_url, session):
    url = urljoin(base_url, '/tt-players/')
    items = paged_fetch(session, url)
    write_json(os.path.join(OUT_DIR, 'tt_players.json'), items)

    histories = {}
    for p in items:
        pid = p.get('id')
        if not pid:
            continue
        r = session.get(urljoin(base_url, f'/tt-players/{pid}'), timeout=30)
        if r.status_code != 200:
            continue
        detail = r.json()
        hist = detail.get('ranking_history')
        if hist:
            histories[str(pid)] = hist
    write_json(os.path.join(OUT_DIR, 'tt_player_histories.json'), histories)

def export_generic_list(base_path, out_name, base_url, session):
    url = urljoin(base_url, base_path)
    items = paged_fetch(session, url)
    write_json(os.path.join(OUT_DIR, out_name), items)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base', default='http://localhost:8000', help='Backend base URL')
    args = parser.parse_args()

    session = requests.Session()

    print('Exporting players...')
    export_players(args.base, session)
    print('Exporting table tennis players...')
    export_tt_players(args.base, session)
    print('Exporting football national teams...')
    export_generic_list('/football-national-teams/', 'football_national_teams.json', args.base, session)
    print('Exporting basketball clubs...')
    export_generic_list('/basketball-clubs/', 'basketball_clubs.json', args.base, session)

    print('Done.')

if __name__ == '__main__':
    main()
