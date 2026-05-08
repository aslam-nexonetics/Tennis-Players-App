from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.football_national_team import FootballNationalTeam
from app.schemas.football_national_team import FootballNationalTeamCreate, FootballNationalTeamUpdate
from typing import List, Optional

class FootballNationalTeamService:
    @staticmethod
    def get_team(db: Session, team_id: int):
        return db.query(FootballNationalTeam).filter(FootballNationalTeam.id == team_id).first()

    @staticmethod
    def get_teams(db: Session, skip: int = 0, limit: int = 100, category: Optional[str] = None):
        query = db.query(FootballNationalTeam)
        if category:
            query = query.filter(FootballNationalTeam.category == category)
        total = query.with_entities(func.count(FootballNationalTeam.id)).scalar()
        items = query.order_by(FootballNationalTeam.ranking.asc().nullslast()).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_teams(db: Session, query: str, skip: int = 0, limit: int = 20, category: Optional[str] = None):
        search_filter = FootballNationalTeam.name.ilike(f"%{query}%")
        q = db.query(FootballNationalTeam).filter(search_filter)
        if category:
            q = q.filter(FootballNationalTeam.category == category)
        total = q.with_entities(func.count(FootballNationalTeam.id)).scalar()
        items = q.order_by(FootballNationalTeam.ranking.asc().nullslast()).offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_teams(db: Session, limit: int = 10, category: Optional[str] = None):
        query = db.query(FootballNationalTeam).filter(FootballNationalTeam.ranking != None)
        if category:
            query = query.filter(FootballNationalTeam.category == category)
        return query.order_by(FootballNationalTeam.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_team(db: Session, team_data: FootballNationalTeamCreate):
        db_team = db.query(FootballNationalTeam).filter(
            FootballNationalTeam.name == team_data.name,
            FootballNationalTeam.category == team_data.category
        ).first()
        if db_team:
            for key, value in team_data.model_dump(exclude_unset=True).items():
                setattr(db_team, key, value)
        else:
            db_team = FootballNationalTeam(**team_data.model_dump())
            db.add(db_team)
        
        db.commit()
        return db_team
