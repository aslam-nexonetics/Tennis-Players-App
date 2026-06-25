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
        with_dob = db.query(TableTennisHistoricalPlayer).filter(TableTennisHistoricalPlayer.birth_year != None).count()
        print(f"Total historical table tennis players: {total}")
        print(f"Historical table tennis players with Date of Birth: {with_dob}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
