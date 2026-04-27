from sqlalchemy import Column, Integer, String, DateTime, Text, JSON, Index
from sqlalchemy.sql import func
from app.db.session import Base

class BasketballClub(Base):
    __tablename__ = "basketball_clubs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    city = Column(String, index=True)
    country = Column(String, index=True)
    league = Column(String, index=True) # NBA, EuroLeague, etc.
    conference = Column(String) # Eastern, Western
    founded_year = Column(Integer)
    arena = Column(String)
    capacity = Column(Integer)
    head_coach = Column(String)
    nickname = Column(String)
    image_url = Column(String)
    website = Column(String)
    description = Column(Text)
    
    # Rankings & Stats
    ranking = Column(Integer, index=True) # Power Ranking
    titles = Column(Integer, default=0) # e.g., NBA Championships
    playoff_appearances = Column(Integer, default=0)
    market_value = Column(String)
    current_season_record = Column(String) # e.g., "45-20"
    
    # Key Personnel
    star_player = Column(String)
    owner = Column(String)
    general_manager = Column(String)
    
    # Detailed Honors
    # Example: {"NBA Titles": 17, "Conference Titles": 32, "Division Titles": 25}
    honors_json = Column(JSON)

    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_basketball_clubs_name_lower", func.lower(name)),
    )
