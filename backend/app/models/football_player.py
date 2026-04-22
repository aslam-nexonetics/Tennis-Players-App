from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index
from sqlalchemy.sql import func
from app.db.session import Base


class FootballPlayer(Base):
    __tablename__ = "football_players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String)
    ranking = Column(Integer, index=True) # Ranking in some list (e.g. Top 100)
    current_club = Column(String)
    position = Column(String)
    birth_date = Column(Date)
    height = Column(String)
    weight = Column(String)
    market_value = Column(String)
    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    image_url = Column(String)
    source = Column(String)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_football_players_name_lower", func.lower(name)),
    )
