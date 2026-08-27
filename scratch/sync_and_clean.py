import os
import sys
import json
import requests
from datetime import datetime, date
from sqlalchemy import create_engine, text

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

REMOTE_DB_URL = "postgresql://neondb_owner:npg_48uqktSjVLpR@ep-damp-resonance-anwqigab.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require"
engine = create_engine(REMOTE_DB_URL)

target_date_str = "2026-08-24"
d_obj = datetime.strptime(target_date_str, "%Y-%m-%d").date()
y, m, d = d_obj.year, d_obj.month, d_obj.day

print("=== 1. FETCHING WTA RANKINGS VIA API ===")
url_wta = f"https://api.wtatennis.com/tennis/players/ranked?metric=SINGLES&type=rankSingles&sort=asc&at={target_date_str}&pageSize=100&page=0"
headers = {"User-Agent": "Mozilla/5.0"}
r_wta = requests.get(url_wta, headers=headers, timeout=10)
wta_rows = []
if r_wta.status_code == 200:
    for item in r_wta.json():
        p_info = item.get("player", {})
        fn = p_info.get("firstName", "").strip()
        ln = p_info.get("lastName", "").strip()
        name = f"{fn} {ln}".strip()
        rank = item.get("ranking", 0)
        pts = item.get("points", 0)
        country = p_info.get("countryCode", "Unknown")
        dob = p_info.get("dateOfBirth")
        if name and rank:
            wta_rows.append({"name": name, "rank": rank, "points": pts, "country": country, "wta_dob": dob})
print(f"Retrieved {len(wta_rows)} WTA rankings.")

with engine.connect() as conn:
    # 2. INSERT WTA RANKINGS FOR 2026-08-24
    t_players = conn.execute(text("SELECT id, LOWER(first_name), LOWER(last_name) FROM tennis_players_historical WHERE gender = 1")).fetchall()
    t_cache = {(r[1], r[2]): r[0] for r in t_players}
    inserted = 0

    for r in wta_rows:
        parts = r["name"].split()
        fn = parts[0] if parts else ""
        ln = " ".join(parts[1:]) if len(parts) > 1 else ""
        key = (fn.lower(), ln.lower())
        pid = t_cache.get(key)
        if not pid:
            ins = conn.execute(text("""
                INSERT INTO tennis_players_historical (first_name, last_name, gender, country, last_updated)
                VALUES (:fn, :ln, 1, :c, NOW())
                RETURNING id
            """), {"fn": fn, "ln": ln, "c": r["country"]}).fetchone()
            pid = ins[0]
            t_cache[key] = pid

        ex = conn.execute(text("""
            SELECT id FROM tennis_rankings_historical
            WHERE player_id = :pid AND ranking_year = :y AND ranking_month = :m AND ranking_date = :d
        """), {"pid": pid, "y": y, "m": m, "d": d}).fetchone()
        if not ex:
            conn.execute(text("""
                INSERT INTO tennis_rankings_historical (player_id, rank, points, ranking_year, ranking_month, ranking_date)
                VALUES (:pid, :rk, :pts, :y, :m, :d)
            """), {"pid": pid, "rk": r["rank"], "pts": r["points"], "y": y, "m": m, "d": d})
            inserted += 1

    conn.commit()
    print(f"Inserted {inserted} new WTA rankings into Remote DB.")

    # 3. DEDUPLICATE & SANITIZE ACTIVE TABLES
    print("\n=== 2. SANITIZING ACTIVE PLAYER TABLES ===")
    conn.execute(text("UPDATE players SET ranking = NULL"))
    conn.execute(text("UPDATE table_tennis_players SET ranking = NULL"))
    conn.commit()

    # Tennis M
    lat_atp = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical r
        JOIN tennis_players_historical p ON r.player_id = p.id
        WHERE p.gender = 0
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC LIMIT 1
    """)).fetchone()

    # Tennis F
    lat_wta = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical r
        JOIN tennis_players_historical p ON r.player_id = p.id
        WHERE p.gender = 1
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC LIMIT 1
    """)).fetchone()

    if lat_atp:
        conn.execute(text("""
            WITH ranked_atp AS (
                SELECT p.first_name || ' ' || p.last_name AS full_name, r.rank,
                       ROW_NUMBER() OVER (PARTITION BY r.rank ORDER BY p.id) as rn
                FROM tennis_rankings_historical r
                JOIN tennis_players_historical p ON r.player_id = p.id
                WHERE p.gender = 0
                  AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
            )
            UPDATE players pl
            SET ranking = ra.rank
            FROM ranked_atp ra
            WHERE pl.gender = 'M' AND LOWER(pl.name) = LOWER(ra.full_name) AND ra.rn = 1
        """), {"y": lat_atp[0], "m": lat_atp[1], "d": lat_atp[2]})
        conn.commit()

    if lat_wta:
        conn.execute(text("""
            WITH ranked_wta AS (
                SELECT p.first_name || ' ' || p.last_name AS full_name, r.rank,
                       ROW_NUMBER() OVER (PARTITION BY r.rank ORDER BY p.id) as rn
                FROM tennis_rankings_historical r
                JOIN tennis_players_historical p ON r.player_id = p.id
                WHERE p.gender = 1
                  AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
            )
            UPDATE players pl
            SET ranking = rw.rank
            FROM ranked_wta rw
            WHERE pl.gender = 'F' AND LOWER(pl.name) = LOWER(rw.full_name) AND rw.rn = 1
        """), {"y": lat_wta[0], "m": lat_wta[1], "d": lat_wta[2]})
        conn.commit()

    # Table Tennis M
    lat_tt_m = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 0
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC LIMIT 1
    """)).fetchone()

    # Table Tennis F
    lat_tt_f = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 1
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC LIMIT 1
    """)).fetchone()

    if lat_tt_m:
        conn.execute(text("""
            WITH ranked_tt_m AS (
                SELECT p.first_name || ' ' || p.last_name AS full_name_fl,
                       p.last_name || ' ' || p.first_name AS full_name_lf,
                       r.rank,
                       ROW_NUMBER() OVER (PARTITION BY r.rank ORDER BY p.id) as rn
                FROM tt_rankings_historical r
                JOIN tt_players_historical p ON r.player_id = p.id
                WHERE p.gender = 0
                  AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
            )
            UPDATE table_tennis_players pl
            SET ranking = rtm.rank
            FROM ranked_tt_m rtm
            WHERE pl.gender = 'M' 
              AND (LOWER(pl.name) = LOWER(rtm.full_name_fl) OR LOWER(pl.name) = LOWER(rtm.full_name_lf))
              AND rtm.rn = 1
        """), {"y": lat_tt_m[0], "m": lat_tt_m[1], "d": lat_tt_m[2]})
        conn.commit()

    if lat_tt_f:
        conn.execute(text("""
            WITH ranked_tt_f AS (
                SELECT p.first_name || ' ' || p.last_name AS full_name_fl,
                       p.last_name || ' ' || p.first_name AS full_name_lf,
                       r.rank,
                       ROW_NUMBER() OVER (PARTITION BY r.rank ORDER BY p.id) as rn
                FROM tt_rankings_historical r
                JOIN tt_players_historical p ON r.player_id = p.id
                WHERE p.gender = 1
                  AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
            )
            UPDATE table_tennis_players pl
            SET ranking = rtf.rank
            FROM ranked_tt_f rtf
            WHERE pl.gender = 'F' 
              AND (LOWER(pl.name) = LOWER(rtf.full_name_fl) OR LOWER(pl.name) = LOWER(rtf.full_name_lf))
              AND rtf.rn = 1
        """), {"y": lat_tt_f[0], "m": lat_tt_f[1], "d": lat_tt_f[2]})
        conn.commit()

    print("Active player tables updated and deduplicated successfully!")

    # 4. EXPORT OFFLINE ASSET JSON FILES
    print("\n=== 3. EXPORTING CLEAN JSON ASSETS ===")
    out_dir = os.path.join(project_root, "frontend", "assets", "data")
    os.makedirs(out_dir, exist_ok=True)

    # Tennis players.json
    t_players = [dict(r._mapping) for r in conn.execute(text("SELECT id, first_name, last_name, country, gender, picture, prize_money, birth_year, birth_month, birth_date, last_updated FROM tennis_players_historical"))]
    atp_ranks = {r[0]: r[1] for r in conn.execute(text("SELECT player_id, rank FROM tennis_rankings_historical WHERE ranking_year = :y AND ranking_month = :m AND ranking_date = :d"), {"y": lat_atp[0], "m": lat_atp[1], "d": lat_atp[2]})} if lat_atp else {}
    wta_ranks = {r[0]: r[1] for r in conn.execute(text("SELECT player_id, rank FROM tennis_rankings_historical WHERE ranking_year = :y AND ranking_month = :m AND ranking_date = :d"), {"y": lat_wta[0], "m": lat_wta[1], "d": lat_wta[2]})} if lat_wta else {}

    ch_res = conn.execute(text("""
        SELECT DISTINCT ON (player_id) player_id, rank, ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical WHERE rank > 0
        ORDER BY player_id, rank ASC, ranking_year ASC, ranking_month ASC, ranking_date ASC
    """))
    ch_dict = {}
    for r in ch_res:
        try: ch_d = date(r[2], r[3], r[4]).isoformat()
        except ValueError: ch_d = None
        ch_dict[r[0]] = {"rank": r[1], "date": ch_d}

    final_t = []
    for p in t_players:
        pid = p["id"]
        g_str = "M" if p["gender"] == 0 else "F"
        cur_rank = atp_ranks.get(pid) if g_str == "M" else wta_ranks.get(pid)
        b_d = None
        if p["birth_year"] and p["birth_month"] and p["birth_date"]:
            try: b_d = date(p["birth_year"], p["birth_month"], p["birth_date"]).isoformat()
            except ValueError: pass
        ch = ch_dict.get(pid, {})
        final_t.append({
            "id": pid,
            "name": f"{p['first_name']} {p['last_name']}",
            "country": p["country"],
            "ranking": cur_rank,
            "birth_date": b_d,
            "prize_money": p["prize_money"] or "Unknown",
            "image_url": p["picture"],
            "source": "ATP/WTA Historical Database",
            "gender": g_str,
            "last_updated": p["last_updated"].isoformat() if isinstance(p["last_updated"], (date, datetime)) else p["last_updated"],
            "highest_ranking": ch.get("rank"),
            "highest_ranking_date": ch.get("date"),
            "career_high_rank": ch.get("rank"),
            "career_high_date": ch.get("date")
        })

    with open(os.path.join(out_dir, "players.json"), "w", encoding="utf-8") as f:
        json.dump(final_t, f, ensure_ascii=False, indent=2)
    print(f"Exported players.json ({len(final_t)} players)")

    # TT tt_players.json
    tt_players = [dict(r._mapping) for r in conn.execute(text("SELECT id, first_name, last_name, country, gender, picture, last_updated FROM tt_players_historical"))]
    tt_m_ranks = {r[0]: r[1] for r in conn.execute(text("SELECT player_id, rank FROM tt_rankings_historical WHERE ranking_year = :y AND ranking_month = :m AND ranking_date = :d"), {"y": lat_tt_m[0], "m": lat_tt_m[1], "d": lat_tt_m[2]})} if lat_tt_m else {}
    tt_f_ranks = {r[0]: r[1] for r in conn.execute(text("SELECT player_id, rank FROM tt_rankings_historical WHERE ranking_year = :y AND ranking_month = :m AND ranking_date = :d"), {"y": lat_tt_f[0], "m": lat_tt_f[1], "d": lat_tt_f[2]})} if lat_tt_f else {}

    tt_ch_res = conn.execute(text("""
        SELECT DISTINCT ON (player_id) player_id, rank, ranking_year, ranking_month, ranking_date
        FROM tt_rankings_historical WHERE rank > 0
        ORDER BY player_id, rank ASC, ranking_year ASC, ranking_month ASC, ranking_date ASC
    """))
    tt_ch_dict = {}
    for r in tt_ch_res:
        try: ch_d = date(r[2], r[3], r[4]).isoformat()
        except ValueError: ch_d = None
        tt_ch_dict[r[0]] = {"rank": r[1], "date": ch_d}

    final_tt = []
    for p in tt_players:
        pid = p["id"]
        g_str = "M" if p["gender"] == 0 else "F"
        # Crucial fix for duplicate ranks: ONLY set ranking if the player was ranked in the LATEST checkpoint!
        cur_rank = tt_m_ranks.get(pid) if g_str == "M" else tt_f_ranks.get(pid)
        ch = tt_ch_dict.get(pid, {})
        final_tt.append({
            "id": pid,
            "name": f"{p['first_name']} {p['last_name']}".strip(),
            "country": p["country"],
            "ranking": cur_rank,
            "image_url": p["picture"],
            "source": "WTT Historical Database",
            "gender": g_str,
            "last_updated": p["last_updated"].isoformat() if isinstance(p["last_updated"], (date, datetime)) else p["last_updated"],
            "career_high_rank": ch.get("rank"),
            "career_high_date": ch.get("date")
        })

    with open(os.path.join(out_dir, "tt_players.json"), "w", encoding="utf-8") as f:
        json.dump(final_tt, f, ensure_ascii=False, indent=2)
    print(f"Exported tt_players.json ({len(final_tt)} players)")

print("\n✅ Sync & clean completed successfully!")
