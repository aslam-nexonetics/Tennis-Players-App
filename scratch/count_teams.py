import sys
import os

# Add project root to sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal
from app.models.football_national_team import FootballNationalTeam

def count_teams():
    db = SessionLocal()
    try:
        count = db.query(FootballNationalTeam).count()
        print(f"Total football national teams: {count}")
        
        men_count = db.query(FootballNationalTeam).filter(FootballNationalTeam.category == 'men').count()
        women_count = db.query(FootballNationalTeam).filter(FootballNationalTeam.category == 'women').count()
        print(f"Men teams: {men_count}")
        print(f"Women teams: {women_count}")
        
    finally:
        db.close()

if __name__ == "__main__":
    count_teams()
