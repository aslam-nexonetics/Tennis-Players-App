import os
import sys
from dotenv import load_dotenv

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(os.path.join(project_root, 'backend'))
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer

def main():
    db = SessionLocal()
    try:
        countries = [r[0] for r in db.query(TableTennisHistoricalPlayer.country).distinct().all() if r[0]]
        print("Unique countries in database:", sorted(countries))
    finally:
        db.close()

if __name__ == "__main__":
    main()
