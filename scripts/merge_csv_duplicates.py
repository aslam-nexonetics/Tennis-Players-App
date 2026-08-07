import os
import sys
import csv
import re
import json
from dotenv import load_dotenv

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from sqlalchemy import create_engine, text, func
from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer, TableTennisHistoricalRanking

def clean_name_str(s: str) -> str:
    if not s:
        return ""
    s = s.replace('^^', ' ')
    s = re.sub(r'\s+', ' ', s)
    return s.strip()

def main():
    db = SessionLocal()
    csv_path = os.path.join(project_root, 'duplicate_table_tennis_players.csv')

    print(f"Reading duplicates list from {csv_path}...")

    try:
        merged_count = 0
        removed_count = 0

        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader, None)

            for row_idx, row in enumerate(reader, start=2):
                if not row or len(row) < 4:
                    continue
                
                fn_csv, ln_csv, count_str, ids_str = row[0], row[1], row[2], row[3]
                pids = [int(x.strip()) for x in ids_str.split(',') if x.strip()]

                # Fetch player records
                players = db.query(TableTennisHistoricalPlayer).filter(
                    TableTennisHistoricalPlayer.id.in_(pids)
                ).all()

                if len(players) < 2:
                    # Already merged or missing
                    continue

                # Fetch ranking counts for scoring
                counts_res = db.query(
                    TableTennisHistoricalRanking.player_id,
                    func.count(TableTennisHistoricalRanking.id)
                ).filter(
                    TableTennisHistoricalRanking.player_id.in_([p.id for p in players])
                ).group_by(TableTennisHistoricalRanking.player_id).all()
                
                rk_counts = {r[0]: r[1] for r in counts_res}

                def score(p):
                    s = 0
                    if p.picture and p.picture.strip():
                        s += 500
                    if p.birth_year:
                        s += 100
                    s += rk_counts.get(p.id, 0)
                    orig = f"{p.first_name} {p.last_name}"
                    if '^^' not in orig:
                        s += 20
                    return s

                players_sorted = sorted(players, key=score, reverse=True)
                primary = players_sorted[0]
                secondaries = players_sorted[1:]

                # Clean name
                clean_fn = clean_name_str(primary.first_name)
                clean_ln = clean_name_str(primary.last_name)
                primary.first_name = clean_fn
                primary.last_name = clean_ln

                primary_name = f"{clean_fn} {clean_ln}"
                print(f"[{row_idx}] Primary ID {primary.id}: '{primary_name}' (Pic={bool(primary.picture)}, DOB={primary.birth_year}, Ranks={rk_counts.get(primary.id, 0)})")

                for sec in secondaries:
                    sec_name = f"{sec.first_name} {sec.last_name}"
                    print(f"    <- Merging Secondary ID {sec.id}: '{sec_name}' (Pic={bool(sec.picture)}, DOB={sec.birth_year}, Ranks={rk_counts.get(sec.id, 0)})")

                    # Inherit missing fields
                    if (not primary.picture or not primary.picture.strip()) and sec.picture:
                        primary.picture = sec.picture
                    if not primary.birth_year and sec.birth_year:
                        primary.birth_year = sec.birth_year
                        primary.birth_month = sec.birth_month
                        primary.birth_date = sec.birth_date
                    if (not primary.country or primary.country.upper() == 'UNKNOWN') and sec.country:
                        primary.country = sec.country

                    # Bulk delete colliding ranking dates using Postgres JOIN
                    db.execute(text("""
                        DELETE FROM tt_rankings_historical r1
                        USING tt_rankings_historical r2
                        WHERE r1.player_id = :sec_id
                          AND r2.player_id = :primary_id
                          AND r1.ranking_year = r2.ranking_year
                          AND r1.ranking_month = r2.ranking_month
                          AND r1.ranking_date = r2.ranking_date
                    """), {"sec_id": sec.id, "primary_id": primary.id})

                    # Bulk update remaining rankings to primary
                    db.execute(text("""
                        UPDATE tt_rankings_historical
                        SET player_id = :primary_id
                        WHERE player_id = :sec_id
                    """), {"sec_id": sec.id, "primary_id": primary.id})

                    # Bulk delete secondary player
                    db.execute(text("""
                        DELETE FROM tt_players_historical
                        WHERE id = :sec_id
                    """), {"sec_id": sec.id})

                    removed_count += 1

                merged_count += 1

        db.commit()
        print(f"\n✅ SUCCESS: Merged {merged_count} duplicate pairs/clusters from CSV and removed {removed_count} secondary player records!")

    except Exception as e:
        db.rollback()
        print(f"Error during CSV deduplication: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    main()
