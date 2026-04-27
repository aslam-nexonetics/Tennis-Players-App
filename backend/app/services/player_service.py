from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.player import Player
from app.schemas.player import PlayerCreate, PlayerUpdate
from typing import List, Optional

class PlayerService:
    @staticmethod
    def get_player(db: Session, player_id: int):
        return db.query(Player).filter(Player.id == player_id).first()

    @staticmethod
    def get_players(db: Session, skip: int = 0, limit: int = 100, gender: Optional[str] = None):
        query = db.query(Player)
        if gender:
            query = query.filter(Player.gender == gender)
        total = query.with_entities(func.count(Player.id)).scalar()
        items = query.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_players(db: Session, query: str, skip: int = 0, limit: int = 20, gender: Optional[str] = None):
        search_filter = func.lower(Player.name).contains(func.lower(query))
        q = db.query(Player).filter(search_filter)
        if gender:
            q = q.filter(Player.gender == gender)
        total = q.with_entities(func.count(Player.id)).scalar()
        items = q.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_players(db: Session, limit: int = 10, gender: Optional[str] = None):
        query = db.query(Player).filter(Player.ranking != None)
        if gender:
            query = query.filter(Player.gender == gender)
        return query.order_by(Player.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_player(db: Session, player_data: PlayerCreate):
        db_player = db.query(Player).filter(Player.name == player_data.name).first()
        if db_player:
            for key, value in player_data.model_dump(exclude_unset=True).items():
                setattr(db_player, key, value)
        else:
            db_player = Player(**player_data.model_dump())
            db.add(db_player)
        
        db.commit()
        db.refresh(db_player)
        return db_player
