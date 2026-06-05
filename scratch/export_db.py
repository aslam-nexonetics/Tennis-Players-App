import os
import sys
import json
import csv
from datetime import date, datetime

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from dotenv import load_dotenv
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.player import Player
from app.models.tt_player import TableTennisPlayer
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

def export_table(db, model, name, json_path, csv_path):
    print(f"Exporting {name}...")
    rows = db.query(model).all()
    dicts = [row_to_dict(r) for r in rows]
    
    # Save as JSON
    os.makedirs(os.path.dirname(json_path), exist_ok=True)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dicts, f, cls=DateTimeEncoder, indent=2, ensure_ascii=False)
    print(f"  Saved JSON to {json_path} ({len(dicts)} rows)")
    
    # Save as CSV (for Excel)
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
            (Player, "Tennis Players", "players.json", "players.csv"),
            (TableTennisPlayer, "Table Tennis Players", "tt_players.json", "tt_players.csv"),
            (FootballNationalTeam, "Football National Teams", "football_national_teams.json", "football_national_teams.csv"),
            (BasketballClub, "Basketball Clubs", "basketball_clubs.json", "basketball_clubs.csv")
        ]
        
        json_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'frontend', 'assets', 'data'))
        csv_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scratch'))
        
        for model, name, json_name, csv_name in tables:
            json_path = os.path.join(json_dir, json_name)
            csv_path = os.path.join(csv_dir, csv_name)
            export_table(db, model, name, json_path, csv_path)
            
        print("All tables successfully exported.")
    except Exception as e:
        print(f"Error during export: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    main()
