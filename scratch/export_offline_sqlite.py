import os
import json
import sqlite3
from datetime import date, datetime

db_path = "/home/nexonetics/nexonetics/tennis_app/tennis.db"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

print("--- EXPORTING TENNIS OFFLINE ASSETS ---")

# 1. Latest Tennis Date
cursor.execute("""
    SELECT ranking_year, ranking_month, ranking_date 
    FROM tennis_rankings_historical 
    ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC 
    LIMIT 1
""")
tennis_latest = cursor.fetchone()
ly, lm, ld = tennis_latest['ranking_year'], tennis_latest['ranking_month'], tennis_latest['ranking_date']
print(f"Tennis Latest Ranking Date: {ly}-{lm:02d}-{ld:02d}")

# Get all tennis players
cursor.execute("SELECT id, first_name, last_name, country, gender, picture, prize_money, birth_year, birth_month, birth_date, last_updated FROM tennis_players_historical")
tennis_players = [dict(r) for r in cursor.fetchall()]
print(f"Loaded {len(tennis_players)} tennis historical players.")

# Latest ranks per player
cursor.execute("""
    SELECT player_id, rank 
    FROM tennis_rankings_historical 
    WHERE ranking_year = ? AND ranking_month = ? AND ranking_date = ?
""", (ly, lm, ld))
latest_tennis_ranks = {r['player_id']: r['rank'] for r in cursor.fetchall()}

# Career high ranks per player (min rank > 0)
cursor.execute("""
    SELECT player_id, rank, ranking_year, ranking_month, ranking_date
    FROM tennis_rankings_historical
    WHERE rank > 0
    GROUP BY player_id
    HAVING rank = MIN(rank)
""")
tennis_career_highs = {}
for r in cursor.fetchall():
    pid = r['player_id']
    try:
        ch_date = date(r['ranking_year'], r['ranking_month'], r['ranking_date']).isoformat()
    except ValueError:
        ch_date = None
    tennis_career_highs[pid] = {
        "rank": r['rank'],
        "date": ch_date
    }

# Ranking histories
cursor.execute("""
    SELECT player_id, rank, ranking_year, ranking_month, ranking_date
    FROM tennis_rankings_historical
    WHERE rank > 0
    ORDER BY player_id, ranking_year ASC, ranking_month ASC, ranking_date ASC
""")
raw_tennis_histories = {}
for r in cursor.fetchall():
    pid = r['player_id']
    try:
        h_date = date(r['ranking_year'], r['ranking_month'], r['ranking_date']).isoformat()
    except ValueError:
        continue
    raw_tennis_histories.setdefault(pid, []).append({
        "ranking": r['rank'],
        "date": h_date
    })

sampled_tennis_histories = {}
for pid, h_list in raw_tennis_histories.items():
    if len(h_list) <= 20:
        sampled_tennis_histories[pid] = h_list
    else:
        n = len(h_list)
        sampled = []
        for i in range(20):
            idx = int(i * (n - 1) / 19)
            sampled.append(h_list[idx])
        sampled_tennis_histories[pid] = sampled

final_tennis_players = []
for p in tennis_players:
    pid = p["id"]
    full_name = f"{p['first_name']} {p['last_name']}".strip()
    b_date = None
    if p["birth_year"] and p["birth_month"] and p["birth_date"]:
        try:
            b_date = date(p["birth_year"], p["birth_month"], p["birth_date"]).isoformat()
        except ValueError:
            pass

    ch = tennis_career_highs.get(pid, {})
    final_tennis_players.append({
        "id": pid,
        "name": full_name,
        "country": p["country"],
        "ranking": latest_tennis_ranks.get(pid),
        "birth_date": b_date,
        "prize_money": p["prize_money"] or "Unknown",
        "image_url": p["picture"],
        "source": "ATP/WTA Historical Database",
        "gender": "M" if p["gender"] == 0 else "F",
        "last_updated": p["last_updated"],
        "highest_ranking": ch.get("rank"),
        "highest_ranking_date": ch.get("date"),
        "career_high_rank": ch.get("rank"),
        "career_high_date": ch.get("date")
    })

players_path = "frontend/assets/data/players.json"
histories_path = "frontend/assets/data/player_histories.json"
with open(players_path, "w", encoding="utf-8") as f:
    json.dump(final_tennis_players, f, ensure_ascii=False, indent=2)
print(f"Wrote {len(final_tennis_players)} items to {players_path}")

with open(histories_path, "w", encoding="utf-8") as f:
    json.dump(sampled_tennis_histories, f, ensure_ascii=False, indent=2)
print(f"Wrote {len(sampled_tennis_histories)} items to {histories_path}")

print("\n--- EXPORTING TABLE TENNIS OFFLINE ASSETS ---")

# 2. Latest Table Tennis Date
cursor.execute("""
    SELECT ranking_year, ranking_month, ranking_date 
    FROM tt_rankings_historical 
    ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC 
    LIMIT 1
""")
tt_latest = cursor.fetchone()
tty, ttm, ttd = tt_latest['ranking_year'], tt_latest['ranking_month'], tt_latest['ranking_date']
print(f"Table Tennis Latest Ranking Date: {tty}-{ttm:02d}-{ttd:02d}")

# Get all TT players
cursor.execute("SELECT id, first_name, last_name, country, gender, picture, birth_year, birth_month, birth_date, last_updated FROM tt_players_historical")
tt_players = [dict(r) for r in cursor.fetchall()]
print(f"Loaded {len(tt_players)} table tennis historical players.")

# Latest TT ranks per player
cursor.execute("""
    SELECT player_id, rank 
    FROM tt_rankings_historical 
    WHERE ranking_year = ? AND ranking_month = ? AND ranking_date = ?
""", (tty, ttm, ttd))
latest_tt_ranks = {r['player_id']: r['rank'] for r in cursor.fetchall()}

# Career high TT ranks
cursor.execute("""
    SELECT player_id, rank, ranking_year, ranking_month, ranking_date
    FROM tt_rankings_historical
    WHERE rank > 0
    GROUP BY player_id
    HAVING rank = MIN(rank)
""")
tt_career_highs = {}
for r in cursor.fetchall():
    pid = r['player_id']
    try:
        ch_date = date(r['ranking_year'], r['ranking_month'], r['ranking_date']).isoformat()
    except ValueError:
        ch_date = None
    tt_career_highs[pid] = {
        "rank": r['rank'],
        "date": ch_date
    }

# TT Ranking histories
cursor.execute("""
    SELECT player_id, rank, ranking_year, ranking_month, ranking_date
    FROM tt_rankings_historical
    WHERE rank > 0
    ORDER BY player_id, ranking_year ASC, ranking_month ASC, ranking_date ASC
""")
raw_tt_histories = {}
for r in cursor.fetchall():
    pid = r['player_id']
    try:
        h_date = date(r['ranking_year'], r['ranking_month'], r['ranking_date']).isoformat()
    except ValueError:
        continue
    raw_tt_histories.setdefault(pid, []).append({
        "ranking": r['rank'],
        "date": h_date
    })

sampled_tt_histories = {}
for pid, h_list in raw_tt_histories.items():
    if len(h_list) <= 20:
        sampled_tt_histories[pid] = h_list
    else:
        n = len(h_list)
        sampled = []
        for i in range(20):
            idx = int(i * (n - 1) / 19)
            sampled.append(h_list[idx])
        sampled_tt_histories[pid] = sampled

final_tt_players = []
for p in tt_players:
    pid = p["id"]
    full_name = f"{p['first_name']} {p['last_name']}".strip()
    b_date = None
    if p["birth_year"] and p["birth_month"] and p["birth_date"]:
        try:
            b_date = date(p["birth_year"], p["birth_month"], p["birth_date"]).isoformat()
        except ValueError:
            pass

    ch = tt_career_highs.get(pid, {})
    final_tt_players.append({
        "id": pid,
        "name": full_name,
        "country": p["country"],
        "ranking": latest_tt_ranks.get(pid),
        "birth_date": b_date,
        "image_url": p["picture"],
        "source": "WTT Historical Database",
        "gender": "M" if p["gender"] == 0 else "F",
        "last_updated": p["last_updated"],
        "highest_ranking": ch.get("rank"),
        "highest_ranking_date": ch.get("date"),
        "career_high_rank": ch.get("rank"),
        "career_high_date": ch.get("date")
    })

tt_players_path = "frontend/assets/data/tt_players.json"
tt_histories_path = "frontend/assets/data/tt_player_histories.json"
with open(tt_players_path, "w", encoding="utf-8") as f:
    json.dump(final_tt_players, f, ensure_ascii=False, indent=2)
print(f"Wrote {len(final_tt_players)} items to {tt_players_path}")

with open(tt_histories_path, "w", encoding="utf-8") as f:
    json.dump(sampled_tt_histories, f, ensure_ascii=False, indent=2)
print(f"Wrote {len(sampled_tt_histories)} items to {tt_histories_path}")

conn.close()
print("\n✅ All offline assets successfully updated!")
