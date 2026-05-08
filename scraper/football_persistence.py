import sys
import os

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal, engine, Base
from app.models.football_national_team import FootballNationalTeam
from sqlalchemy.orm import Session
from scraper.utils.logger import log

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

def save_football_national_team(team_data: dict):
    db = SessionLocal()
    try:
        existing = db.query(FootballNationalTeam).filter(
            FootballNationalTeam.name == team_data['name'],
            FootballNationalTeam.category == team_data.get('category', 'men')
        ).first()
        
        if existing:
            # Update existing record
            for key, value in team_data.items():
                if value is not None:
                    setattr(existing, key, value)
            log.debug(f"Updated National Team: {team_data['name']}")
        else:
            # Create new record
            new_team = FootballNationalTeam(**team_data)
            db.add(new_team)
            log.info(f"Added new National Team: {team_data['name']}")
        
        db.commit()
    except Exception as e:
        db.rollback()
        log.error(f"Failed to save national team {team_data.get('name')}: {e}")
    finally:
        db.close()
