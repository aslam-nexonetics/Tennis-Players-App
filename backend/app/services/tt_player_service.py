from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.tt_player import TableTennisPlayer
from app.schemas.tt_player import TtPlayerCreate, TtPlayerUpdate
from typing import List, Optional


class TtPlayerService:
    @staticmethod
    def get_player(db: Session, player_id: int):
        return db.query(TableTennisPlayer).filter(TableTennisPlayer.id == player_id).first()

    @staticmethod
    def get_players(db: Session, skip: int = 0, limit: int = 100, gender: Optional[str] = None):
        query = db.query(TableTennisPlayer)
        if gender:
            query = query.filter(TableTennisPlayer.gender == gender)
        # Only include players with a ranking
        query = query.filter(TableTennisPlayer.ranking != None).order_by(TableTennisPlayer.ranking.asc())
        total = query.with_entities(func.count(TableTennisPlayer.id)).scalar()
        items = query.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_players(db: Session, query: str, skip: int = 0, limit: int = 20, gender: Optional[str] = None):
        search_filter = func.lower(TableTennisPlayer.name).contains(func.lower(query))
        q = db.query(TableTennisPlayer).filter(search_filter)
        if gender:
            q = q.filter(TableTennisPlayer.gender == gender)
        total = q.with_entities(func.count(TableTennisPlayer.id)).scalar()
        items = q.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_players(db: Session, limit: int = 50, gender: Optional[str] = None):
        query = db.query(TableTennisPlayer).filter(TableTennisPlayer.ranking != None)
        if gender:
            query = query.filter(TableTennisPlayer.gender == gender)
        return query.order_by(TableTennisPlayer.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_player(db: Session, player_data: TtPlayerCreate):
        db_player = db.query(TableTennisPlayer).filter(
            TableTennisPlayer.name == player_data.name
        ).first()
        if db_player:
            for key, value in player_data.model_dump(exclude_unset=True).items():
                setattr(db_player, key, value)
        else:
            db_player = TableTennisPlayer(**player_data.model_dump())
            db.add(db_player)

        db.commit()
        db.refresh(db_player)
        return db_player
