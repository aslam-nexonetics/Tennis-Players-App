from sqlalchemy import Column, Integer, String, DateTime, Index, Text, JSON
from sqlalchemy.sql import func
from app.db.session import Base


class FootballClub(Base):
    __tablename__ = "football_clubs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String, index=True)
    league = Column(String, index=True)
    founded_year = Column(Integer)
    stadium = Column(String)
    capacity = Column(Integer)
    manager = Column(String)
    nickname = Column(String)
    image_url = Column(String)
    website = Column(String)
    description = Column(Text)
    ranking = Column(Integer, index=True) # World Ranking
    
    # Enhanced Statistics
    total_trophies = Column(Integer, default=0)
    market_value = Column(String)
    league_position = Column(Integer)
    domestic_ranking = Column(Integer)
    captain = Column(String)
    owner = Column(String)
    main_rivals = Column(String)
    average_attendance = Column(Integer)
    
    # Detailed Honors (Stored as JSON for flexibility)
    # Example: {"Champions League": 15, "La Liga": 36, "Copa del Rey": 20}
    honors_json = Column(JSON)

    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_football_clubs_name_lower", func.lower(name)),
    )
