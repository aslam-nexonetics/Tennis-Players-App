from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.basketball_player import BasketballPlayer, BasketballRankingHistory
from app.schemas.basketball_player import BasketballPlayerCreate
from typing import List, Optional

class BasketballPlayerService:
    @staticmethod
    def get_player(db: Session, player_id: int):
        return db.query(BasketballPlayer).filter(BasketballPlayer.id == player_id).first()

    @staticmethod
    def get_players(db: Session, skip: int = 0, limit: int = 100):
        total = db.query(func.count(BasketballPlayer.id)).scalar()
        items = db.query(BasketballPlayer).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_players(db: Session, query: str, skip: int = 0, limit: int = 20):
        search_filter = func.lower(BasketballPlayer.name).contains(func.lower(query))
        total = db.query(func.count(BasketballPlayer.id)).filter(search_filter).scalar()
        items = db.query(BasketballPlayer).filter(search_filter).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_players(db: Session, limit: int = 10):
        # Order by PPG as a fallback for ranking if ranking is null
        return db.query(BasketballPlayer).order_by(BasketballPlayer.ranking.asc().nullslast(), BasketballPlayer.ppg.desc()).limit(limit).all()

    @staticmethod
    def create_or_update_player(db: Session, player_data: BasketballPlayerCreate):
        db_player = db.query(BasketballPlayer).filter(BasketballPlayer.name == player_data.name).first()
        
        # Exclude ranking_history as it's a relationship
        update_data = player_data.model_dump(exclude={"ranking_history"}, exclude_unset=True)
        
        if db_player:
            for key, value in update_data.items():
                setattr(db_player, key, value)
        else:
            db_player = BasketballPlayer(**update_data)
            db.add(db_player)
        
        db.commit()
        db.refresh(db_player)
        return db_player

    @staticmethod
    def add_ranking_history(db: Session, history_data):
        db_history = BasketballRankingHistory(**history_data.model_dump())
        db.add(db_history)
        db.commit()
        db.refresh(db_history)
        return db_history
