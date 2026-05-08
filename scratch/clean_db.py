import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from sqlalchemy import text
from app.db.session import SessionLocal, engine, Base

def clean_football_data():
    print("Ensuring tables are created...")
    from app.models.football_national_team import FootballNationalTeam
    from app.models.player import Player
    from app.models.tt_player import TableTennisPlayer
    from app.models.basketball_club import BasketballClub
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        print("Cleaning football_national_teams table...")
        db.execute(text("DELETE FROM football_national_teams"))
        
        # Also try to drop/clean football_clubs if it exists
        try:
            print("Checking for legacy football_clubs table...")
            db.execute(text("DELETE FROM football_clubs"))
            print("Legacy football_clubs table cleaned.")
        except Exception as e:
            print(f"Note: football_clubs table might not exist (which is fine): {e}")
            
        db.commit()
        print("Data cleaning completed successfully.")
    except Exception as e:
        db.rollback()
        print(f"Error during cleaning: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    clean_football_data()
