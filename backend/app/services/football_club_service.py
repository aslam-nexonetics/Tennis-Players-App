from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.football_club import FootballClub
from app.schemas.football_club import FootballClubCreate, FootballClubUpdate
from typing import List, Optional

class FootballClubService:
    @staticmethod
    def get_club(db: Session, club_id: int):
        return db.query(FootballClub).filter(FootballClub.id == club_id).first()

    @staticmethod
    def get_clubs(db: Session, skip: int = 0, limit: int = 100):
        total = db.query(func.count(FootballClub.id)).scalar()
        items = db.query(FootballClub).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_clubs(db: Session, query: str, skip: int = 0, limit: int = 20):
        search_filter = func.lower(FootballClub.name).contains(func.lower(query))
        total = db.query(func.count(FootballClub.id)).filter(search_filter).scalar()
        items = db.query(FootballClub).filter(search_filter).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_clubs(db: Session, limit: int = 10):
        return db.query(FootballClub).filter(FootballClub.ranking != None).order_by(FootballClub.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_club(db: Session, club_data: FootballClubCreate):
        db_club = db.query(FootballClub).filter(FootballClub.name == club_data.name).first()
        if db_club:
            for key, value in club_data.model_dump(exclude_unset=True).items():
                setattr(db_club, key, value)
        else:
            db_club = FootballClub(**club_data.model_dump())
            db.add(db_club)
        
        db.commit()
        db.refresh(db_club)
        return db_club
