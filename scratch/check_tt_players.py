import os
import sys
from dotenv import load_dotenv

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer

def main():
    db = SessionLocal()
    try:
        total = db.query(TableTennisHistoricalPlayer).count()
        missing_dob = db.query(TableTennisHistoricalPlayer).filter(
            (TableTennisHistoricalPlayer.birth_year == None) |
            (TableTennisHistoricalPlayer.birth_month == None) |
            (TableTennisHistoricalPlayer.birth_date == None)
        ).count()
        
        print(f"Total historical table tennis players: {total}")
        print(f"Players missing full DOB (year, month, or day): {missing_dob}")
        
        # Sample missing
        sample = db.query(TableTennisHistoricalPlayer).filter(
            (TableTennisHistoricalPlayer.birth_year == None) |
            (TableTennisHistoricalPlayer.birth_month == None) |
            (TableTennisHistoricalPlayer.birth_date == None)
        ).limit(10).all()
        
        print("\nSample players missing DOB:")
        for p in sample:
            print(f"ID: {p.id} | Name: {p.first_name} {p.last_name} | Country: {p.country} | DOB: {p.birth_year}-{p.birth_month}-{p.birth_date}")
            
    finally:
        db.close()

if __name__ == "__main__":
    main()
