import os
import json
from datetime import date, datetime
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv('backend/.env')
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

print("Fetching latest ranking date...")
with engine.connect() as conn:
    latest_r = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date 
        FROM tennis_rankings_historical 
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC 
        LIMIT 1
    """)).fetchone()
    if not latest_r:
        print("No ranking data found!")
        exit(1)
    
    ly, lm, ld = latest_r
    print(f"Latest ranking date: {ly}-{lm}-{ld}")

    print("Fetching historical players...")
    players_res = conn.execute(text("SELECT id, first_name, last_name, country, gender, picture, prize_money, birth_year, birth_month, birth_date, last_updated FROM tennis_players_historical"))
    players_list = [dict(r._mapping) for r in players_res]
    
    print(f"Loaded {len(players_list)} players.")

    # Pre-fetch latest rankings for all players
    print("Fetching latest rankings for all players...")
    rankings_res = conn.execute(text("""
        SELECT player_id, rank 
        FROM tennis_rankings_historical 
        WHERE ranking_year = :ly AND ranking_month = :lm AND ranking_date = :ld
    """), {"ly": ly, "lm": lm, "ld": ld})
    latest_ranks = {r[0]: r[1] for r in rankings_res}

    # Pre-fetch all career high rankings for all players
    print("Fetching career high rankings for all players...")
    ch_res = conn.execute(text("""
        SELECT DISTINCT ON (player_id) player_id, rank, ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical
        WHERE rank > 0
        ORDER BY player_id, rank ASC, ranking_year ASC, ranking_month ASC, ranking_date ASC
    """))
    career_highs = {}
    for r in ch_res:
        player_id = r[0]
        rank = r[1]
        try:
            ch_date = date(r[2], r[3], r[4]).isoformat()
        except ValueError:
            ch_date = None
        career_highs[player_id] = {
            "rank": rank,
            "date": ch_date
        }

    # Pre-fetch ranking history for all players to construct the histories JSON
    print("Fetching all ranking histories...")
    history_res = conn.execute(text("""
        SELECT player_id, rank, ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical
        WHERE rank > 0
        ORDER BY player_id, ranking_year ASC, ranking_month ASC, ranking_date ASC
    """))
    
    raw_histories = {}
    for r in history_res:
        pid = r[0]
        rank = r[1]
        try:
            h_date = date(r[2], r[3], r[4]).isoformat()
        except ValueError:
            continue
        if pid not in raw_histories:
            raw_histories[pid] = []
        raw_histories[pid].append({
            "ranking": rank,
            "date": h_date
        })

    print("Formatting and sampling ranking histories...")
    sampled_histories = {}
    for pid, h_list in raw_histories.items():
        if len(h_list) <= 20:
            sampled_histories[pid] = h_list
        else:
            n = len(h_list)
            sampled = []
            for i in range(20):
                index = int(i * (n - 1) / 19)
                sampled.append(h_list[index])
            sampled_histories[pid] = sampled

    # Construct final players list
    final_players = []
    for p in players_list:
        pid = p["id"]
        full_name = f"{p['first_name']} {p['last_name']}"
        
        prize_money = p["prize_money"]

        b_date = None
        if p["birth_year"] and p["birth_month"] and p["birth_date"]:
            try:
                b_date = date(p["birth_year"], p["birth_month"], p["birth_date"]).isoformat()
            except ValueError:
                pass

        ch = career_highs.get(pid, {})
        
        final_players.append({
            "id": pid,
            "name": full_name,
            "country": p["country"],
            "ranking": latest_ranks.get(pid),
            "birth_date": b_date,
            "prize_money": prize_money or "Unknown",
            "image_url": p["picture"],
            "source": "ATP/WTA Historical Database",
            "gender": "M" if p["gender"] == 0 else "F",
            "last_updated": p["last_updated"].isoformat() if isinstance(p["last_updated"], (date, datetime)) else p["last_updated"],
            "highest_ranking": ch.get("rank"),
            "highest_ranking_date": ch.get("date"),
            "career_high_rank": ch.get("rank"),
            "career_high_date": ch.get("date")
        })

    # Save to files
    players_path = "frontend/assets/data/players.json"
    histories_path = "frontend/assets/data/player_histories.json"
    
    print(f"Writing to {players_path}...")
    with open(players_path, "w", encoding="utf-8") as f:
        json.dump(final_players, f, ensure_ascii=False)
        
    print(f"Writing to {histories_path}...")
    with open(histories_path, "w", encoding="utf-8") as f:
        json.dump(sampled_histories, f, ensure_ascii=False)

    print("Success!")
