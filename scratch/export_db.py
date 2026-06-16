import os
import sys
import json
import csv
from datetime import date, datetime

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from dotenv import load_dotenv
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.player import Player
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer
from app.models.football_national_team import FootballNationalTeam
from app.models.basketball_club import BasketballClub

class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)

def row_to_dict(row):
    d = {}
    for column in row.__table__.columns:
        d[column.name] = getattr(row, column.name)
    return d

def map_all_historical_tt_players(db: Session):
    print("  Fetching legacy players...")
    legacy_players = db.query(TableTennisPlayer).all()
    legacy_by_name = {lp.name: lp for lp in legacy_players}

    print("  Fetching historical players...")
    players = db.query(TableTennisHistoricalPlayer).all()

    print("  Fetching all historical rankings (ordered via raw SQL)...")
    # Fetch rankings as raw tuples to avoid ORM overhead (about 50-100x faster for 860k records)
    result = db.execute(text(
        "SELECT player_id, rank, points, ranking_year, ranking_month, ranking_date "
        "FROM tt_rankings_historical "
        "ORDER BY ranking_year ASC, ranking_month ASC, ranking_date ASC"
    ))

    print("  Grouping rankings by player in-memory...")
    rankings_by_player = {}
    for row in result:
        pid = row[0]
        if pid not in rankings_by_player:
            rankings_by_player[pid] = []
        rankings_by_player[pid].append(row)

    print("  Mapping players...")
    mapped_dicts = []
    
    for p in players:
        # 1. Get player's ranking list
        p_rankings = rankings_by_player.get(p.id, [])
        
        # 2. Latest rank (last in chronological order)
        latest_r = p_rankings[-1] if p_rankings else None
        rank = latest_r[1] if latest_r else None # row[1] is rank
        
        # 3. Match legacy player
        full_name = f"{p.first_name} {p.last_name}"
        style = None
        win_pct = None
        weight = None
        
        legacy_p = legacy_by_name.get(full_name)
        if legacy_p:
            style = legacy_p.playing_style
            win_pct = legacy_p.win_percentage
            weight = legacy_p.weight
            
        # 4. Birth date
        b_date = None
        if p.birth_year and p.birth_month and p.birth_date:
            try:
                b_date = date(p.birth_year, p.birth_month, p.birth_date)
            except ValueError:
                pass
                
        # 5. Career high rank
        career_high_rank = None
        career_high_date = None
        
        # Filter rankings where rank > 0 (row[1] is rank)
        valid_rankings = [r for r in p_rankings if r[1] > 0]
        if valid_rankings:
            ch_record = min(valid_rankings, key=lambda r: (r[1], r[3], r[4], r[5])) # r[1]=rank, r[3]=year, r[4]=month, r[5]=date
            career_high_rank = ch_record[1]
            try:
                career_high_date = date(ch_record[3], ch_record[4], ch_record[5])
            except ValueError:
                pass
                
        # 6. Sample 20 ranking points
        sampled = []
        if valid_rankings:
            n = len(valid_rankings)
            if n <= 20:
                sampled = valid_rankings
            else:
                for i in range(20):
                    idx = int(i * (n - 1) / 19)
                    sampled.append(valid_rankings[idx])
                    
        ranking_history = []
        for h in sampled:
            try:
                d = date(h[3], h[4], h[5])
                ranking_history.append({
                    "ranking": h[1],
                    "date": d.isoformat()
                })
            except ValueError:
                pass
                
        gender_str = 'M' if p.gender == 0 else ('F' if p.gender == 1 else None)
        
        mapped_dicts.append({
            "id": p.id,
            "name": full_name,
            "country": p.country,
            "ranking": rank,
            "birth_date": b_date.isoformat() if b_date else None,
            "weight": weight,
            "playing_style": style,
            "win_percentage": win_pct,
            "image_url": p.picture,
            "source": "ITTF Database",
            "gender": gender_str,
            "last_updated": p.last_updated.isoformat() if p.last_updated else None,
            "ranking_history": ranking_history,
            "career_high_rank": career_high_rank,
            "career_high_date": career_high_date.isoformat() if career_high_date else None
        })
        
    return mapped_dicts

def export_table(db, model, name, json_path, csv_path, bulk_mapper=None):
    print(f"Exporting {name}...")
    if bulk_mapper:
        dicts = bulk_mapper(db)
    else:
        rows = db.query(model).all()
        dicts = [row_to_dict(r) for r in rows]
    
    # Save as JSON
    os.makedirs(os.path.dirname(json_path), exist_ok=True)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dicts, f, cls=DateTimeEncoder, indent=2, ensure_ascii=False)
    print(f"  Saved JSON to {json_path} ({len(dicts)} rows)")
    
    # Save as CSV (for Excel / backup)
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    if dicts:
        headers = list(dicts[0].keys())
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            for d in dicts:
                # Format dates and JSON fields for CSV readability
                row_data = {}
                for k, v in d.items():
                    if isinstance(v, (datetime, date)):
                        row_data[k] = v.isoformat()
                    elif isinstance(v, (dict, list)):
                        row_data[k] = json.dumps(v, ensure_ascii=False)
                    else:
                        row_data[k] = v
                writer.writerow(row_data)
        print(f"  Saved CSV to {csv_path}")
    else:
        print("  No rows to write to CSV")

def main():
    db: Session = SessionLocal()
    try:
        tables = [
            (Player, "Tennis Players", "players.json", "players.csv", None),
            (TableTennisHistoricalPlayer, "Table Tennis Players", "tt_players.json", "tt_players.csv", map_all_historical_tt_players),
            (FootballNationalTeam, "Football National Teams", "football_national_teams.json", "football_national_teams.csv", None),
            (BasketballClub, "Basketball Clubs", "basketball_clubs.json", "basketball_clubs.csv", None)
        ]
        
        json_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'frontend', 'assets', 'data'))
        csv_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scratch'))
        
        for model, name, json_name, csv_name, mapper in tables:
            json_path = os.path.join(json_dir, json_name)
            csv_path = os.path.join(csv_dir, csv_name)
            export_table(db, model, name, json_path, csv_path, mapper)
            
        print("All tables successfully exported.")
    except Exception as e:
        print(f"Error during export: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    main()
