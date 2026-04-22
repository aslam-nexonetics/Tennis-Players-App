import sys
import os

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal, engine, Base
from app.models.football_player import FootballPlayer
from scraper.utils.logger import log

# Ensure tables are created
Base.metadata.create_all(bind=engine)


def save_football_player(player_data):
    db = SessionLocal()
    try:
        db_player = db.query(FootballPlayer).filter(
            FootballPlayer.name == player_data['name']
        ).first()
        if db_player:
            for key, value in player_data.items():
                setattr(db_player, key, value)
            log.info(f"Updated Football player: {player_data['name']}")
        else:
            db_player = FootballPlayer(**player_data)
            db.add(db_player)
            log.info(f"Added new Football player: {player_data['name']}")

        db.commit()
    except Exception as e:
        db.rollback()
        log.error(f"Error saving Football player {player_data.get('name')}: {e}")
    finally:
        db.close()
