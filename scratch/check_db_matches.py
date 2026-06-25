import os
import sys
from dotenv import load_dotenv

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer

def main():
    db = SessionLocal()
    try:
        active_players = db.query(TableTennisPlayer).all()
        hist_players = db.query(TableTennisHistoricalPlayer).all()
        
        print(f"Total Active Players: {len(active_players)}")
        print(f"Total Historical Players: {len(hist_players)}")
        
        active_by_name = {}
        for ap in active_players:
            if ap.name:
                active_by_name[ap.name.lower()] = ap
                # Also split and reverse just in case
                parts = ap.name.split()
                if len(parts) >= 2:
                    reversed_name = " ".join(reversed(parts))
                    active_by_name[reversed_name.lower()] = ap
                    
        match_count = 0
        dob_sync_count = 0
        
        for hp in hist_players:
            hp_name1 = f"{hp.first_name} {hp.last_name}".strip().lower()
            hp_name2 = f"{hp.last_name} {hp.first_name}".strip().lower()
            
            ap = active_by_name.get(hp_name1) or active_by_name.get(hp_name2)
            if ap:
                match_count += 1
                if ap.birth_date and not hp.birth_year:
                    dob_sync_count += 1
                    
        print(f"Matches: {match_count}")
        print(f"Players that can be enriched from active players table: {dob_sync_count}")
        
    finally:
        db.close()

if __name__ == "__main__":
    main()
