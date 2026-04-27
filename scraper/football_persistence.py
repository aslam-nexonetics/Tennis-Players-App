import sys
import os

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal, engine, Base
from app.models.football_club import FootballClub
from sqlalchemy.orm import Session
from scraper.utils.logger import log

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

def save_football_club(club_data: dict):
    db = SessionLocal()
    try:
        existing = db.query(FootballClub).filter(FootballClub.name == club_data['name']).first()
        
        if existing:
            # Update existing record
            for key, value in club_data.items():
                if value is not None:
                    setattr(existing, key, value)
            log.debug(f"Updated Football club: {club_data['name']}")
        else:
            # Create new record
            new_club = FootballClub(**club_data)
            db.add(new_club)
            log.info(f"Added new Football club: {club_data['name']}")
        
        db.commit()
    except Exception as e:
        db.rollback()
        log.error(f"Failed to save football club {club_data.get('name')}: {e}")
    finally:
        db.close()
