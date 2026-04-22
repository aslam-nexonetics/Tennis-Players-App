from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.football_player import FootballPlayer
from app.schemas.football_player import FootballPlayerCreate, FootballPlayerUpdate
from typing import List, Optional

class FootballPlayerService:
    @staticmethod
    def get_player(db: Session, player_id: int):
        return db.query(FootballPlayer).filter(FootballPlayer.id == player_id).first()

    @staticmethod
    def get_players(db: Session, skip: int = 0, limit: int = 100):
        total = db.query(func.count(FootballPlayer.id)).scalar()
        items = db.query(FootballPlayer).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_players(db: Session, query: str, skip: int = 0, limit: int = 20):
        search_filter = func.lower(FootballPlayer.name).contains(func.lower(query))
        total = db.query(func.count(FootballPlayer.id)).filter(search_filter).scalar()
        items = db.query(FootballPlayer).filter(search_filter).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_players(db: Session, limit: int = 10):
        return db.query(FootballPlayer).filter(FootballPlayer.ranking != None).order_by(FootballPlayer.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_player(db: Session, player_data: FootballPlayerCreate):
        db_player = db.query(FootballPlayer).filter(FootballPlayer.name == player_data.name).first()
        if db_player:
            for key, value in player_data.model_dump(exclude_unset=True).items():
                setattr(db_player, key, value)
        else:
            db_player = FootballPlayer(**player_data.model_dump())
            db.add(db_player)
        
        db.commit()
        db.refresh(db_player)
        return db_player
