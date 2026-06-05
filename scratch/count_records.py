import os
import sys

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from dotenv import load_dotenv
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.player import Player
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer, TableTennisHistoricalRanking
from app.models.football_national_team import FootballNationalTeam
from app.models.basketball_club import BasketballClub

def main():
    db: Session = SessionLocal()
    try:
        tables = {
            "Player": Player,
            "TableTennisPlayer": TableTennisPlayer,
            "TableTennisHistoricalPlayer": TableTennisHistoricalPlayer,
            "TableTennisHistoricalRanking": TableTennisHistoricalRanking,
            "FootballNationalTeam": FootballNationalTeam,
            "BasketballClub": BasketballClub
        }
        for name, model in tables.items():
            try:
                count = db.query(model).count()
                print(f"{name}: {count} records")
            except Exception as e:
                print(f"Error querying {name}: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
