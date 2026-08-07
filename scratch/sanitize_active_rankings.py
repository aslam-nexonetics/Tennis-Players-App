import os
import sys
import json
from datetime import date, datetime
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)

load_dotenv(os.path.join(project_root, 'backend', '.env'))
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

with engine.connect() as conn:
    print("=== 1. SYNCING TENNIS ACTIVE TABLE (players) ===")
    # Get latest date per gender for Tennis
    latest_atp = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical r
        JOIN tennis_players_historical p ON r.player_id = p.id
        WHERE p.gender = 0
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC
        LIMIT 1
    """)).fetchone()
    
    latest_wta = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tennis_rankings_historical r
        JOIN tennis_players_historical p ON r.player_id = p.id
        WHERE p.gender = 1
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC
        LIMIT 1
    """)).fetchone()
    
    print(f"Latest ATP Date: {latest_atp}")
    print(f"Latest WTA Date: {latest_wta}")

    # First reset all rankings in players table to NULL
    conn.execute(text("UPDATE players SET ranking = NULL"))
    conn.commit()

    # Update ATP rankings for current week
    conn.execute(text("""
        WITH latest_atp_ranks AS (
            SELECT p.first_name || ' ' || p.last_name AS full_name, r.rank
            FROM tennis_rankings_historical r
            JOIN tennis_players_historical p ON r.player_id = p.id
            WHERE p.gender = 0
              AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
        )
        UPDATE players pl
        SET ranking = lar.rank
        FROM latest_atp_ranks lar
        WHERE pl.gender = 'M' AND LOWER(pl.name) = LOWER(lar.full_name)
    """), {"y": latest_atp[0], "m": latest_atp[1], "d": latest_atp[2]})
    conn.commit()

    # Update WTA rankings for current week
    conn.execute(text("""
        WITH latest_wta_ranks AS (
            SELECT p.first_name || ' ' || p.last_name AS full_name, r.rank
            FROM tennis_rankings_historical r
            JOIN tennis_players_historical p ON r.player_id = p.id
            WHERE p.gender = 1
              AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
        )
        UPDATE players pl
        SET ranking = lwr.rank
        FROM latest_wta_ranks lwr
        WHERE pl.gender = 'F' AND LOWER(pl.name) = LOWER(lwr.full_name)
    """), {"y": latest_wta[0], "m": latest_wta[1], "d": latest_wta[2]})
    conn.commit()

    # Check Tennis counts
    m_ranked = conn.execute(text("SELECT COUNT(DISTINCT ranking) FROM players WHERE gender = 'M' AND ranking IS NOT NULL")).scalar()
    f_ranked = conn.execute(text("SELECT COUNT(DISTINCT ranking) FROM players WHERE gender = 'F' AND ranking IS NOT NULL")).scalar()
    m_dups = conn.execute(text("SELECT ranking, COUNT(*) FROM players WHERE gender = 'M' AND ranking IS NOT NULL GROUP BY ranking HAVING COUNT(*) > 1")).fetchall()
    f_dups = conn.execute(text("SELECT ranking, COUNT(*) FROM players WHERE gender = 'F' AND ranking IS NOT NULL GROUP BY ranking HAVING COUNT(*) > 1")).fetchall()

    print(f"Tennis Male Ranked Players: {m_ranked} distinct ranks. Duplicates: {m_dups}")
    print(f"Tennis Female Ranked Players: {f_ranked} distinct ranks. Duplicates: {f_dups}")

    print("\n=== 2. SYNCING TABLE TENNIS ACTIVE TABLE (table_tennis_players) ===")
    latest_tt_m = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 0
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC
        LIMIT 1
    """)).fetchone()

    latest_tt_f = conn.execute(text("""
        SELECT ranking_year, ranking_month, ranking_date
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 1
        ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC
        LIMIT 1
    """)).fetchone()

    print(f"Latest TT Male Date: {latest_tt_m}")
    print(f"Latest TT Female Date: {latest_tt_f}")

    # Reset all rankings in table_tennis_players table to NULL
    conn.execute(text("UPDATE table_tennis_players SET ranking = NULL"))
    conn.commit()

    # Update TT Male rankings
    conn.execute(text("""
        WITH latest_tt_m_ranks AS (
            SELECT p.first_name || ' ' || p.last_name AS full_name_fl,
                   p.last_name || ' ' || p.first_name AS full_name_lf,
                   r.rank
            FROM tt_rankings_historical r
            JOIN tt_players_historical p ON r.player_id = p.id
            WHERE p.gender = 0
              AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
        )
        UPDATE table_tennis_players pl
        SET ranking = ltr.rank
        FROM latest_tt_m_ranks ltr
        WHERE pl.gender = 'M' 
          AND (LOWER(pl.name) = LOWER(ltr.full_name_fl) OR LOWER(pl.name) = LOWER(ltr.full_name_lf))
    """), {"y": latest_tt_m[0], "m": latest_tt_m[1], "d": latest_tt_m[2]})
    conn.commit()

    # Update TT Female rankings
    conn.execute(text("""
        WITH latest_tt_f_ranks AS (
            SELECT p.first_name || ' ' || p.last_name AS full_name_fl,
                   p.last_name || ' ' || p.first_name AS full_name_lf,
                   r.rank
            FROM tt_rankings_historical r
            JOIN tt_players_historical p ON r.player_id = p.id
            WHERE p.gender = 1
              AND r.ranking_year = :y AND r.ranking_month = :m AND r.ranking_date = :d
        )
        UPDATE table_tennis_players pl
        SET ranking = ltr.rank
        FROM latest_tt_f_ranks ltr
        WHERE pl.gender = 'F' 
          AND (LOWER(pl.name) = LOWER(ltr.full_name_fl) OR LOWER(pl.name) = LOWER(ltr.full_name_lf))
    """), {"y": latest_tt_f[0], "m": latest_tt_f[1], "d": latest_tt_f[2]})
    conn.commit()

    tt_m_ranked = conn.execute(text("SELECT COUNT(DISTINCT ranking) FROM table_tennis_players WHERE gender = 'M' AND ranking IS NOT NULL")).scalar()
    tt_f_ranked = conn.execute(text("SELECT COUNT(DISTINCT ranking) FROM table_tennis_players WHERE gender = 'F' AND ranking IS NOT NULL")).scalar()
    tt_m_dups = conn.execute(text("SELECT ranking, COUNT(*) FROM table_tennis_players WHERE gender = 'M' AND ranking IS NOT NULL GROUP BY ranking HAVING COUNT(*) > 1")).fetchall()
    tt_f_dups = conn.execute(text("SELECT ranking, COUNT(*) FROM table_tennis_players WHERE gender = 'F' AND ranking IS NOT NULL GROUP BY ranking HAVING COUNT(*) > 1")).fetchall()

    print(f"TT Male Ranked Players: {tt_m_ranked} distinct ranks. Duplicates: {tt_m_dups}")
    print(f"TT Female Ranked Players: {tt_f_ranked} distinct ranks. Duplicates: {tt_f_dups}")
