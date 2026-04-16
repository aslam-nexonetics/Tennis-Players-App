import sys
import os
# Add backend to path to reuse models
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal, engine, Base
from app.models.player import Player
from scraper.utils.logger import log

# Ensure tables are created
Base.metadata.create_all(bind=engine)

def save_player(player_data):
    db = SessionLocal()
    try:
        db_player = db.query(Player).filter(Player.name == player_data['name']).first()
        if db_player:
            for key, value in player_data.items():
                setattr(db_player, key, value)
            log.info(f"Updated player: {player_data['name']}")
        else:
            db_player = Player(**player_data)
            db.add(db_player)
            log.info(f"Added new player: {player_data['name']}")
        
        db.commit()
    except Exception as e:
        db.rollback()
        log.error(f"Error saving player {player_data.get('name')}: {e}")
    finally:
        db.close()
