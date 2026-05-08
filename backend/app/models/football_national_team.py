from sqlalchemy import Column, Integer, String, DateTime, Index, Text, JSON
from sqlalchemy.sql import func
from app.db.session import Base


class FootballNationalTeam(Base):
    __tablename__ = "football_national_teams"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String, index=True)
    confederation = Column(String, index=True) # UEFA, CONMEBOL, etc.
    founded_year = Column(Integer)
    stadium = Column(String)
    nickname = Column(String)
    image_url = Column(String)
    website = Column(String)
    description = Column(Text)
    ranking = Column(Integer, index=True) # FIFA World Ranking
    category = Column(String, index=True, default="men") # 'men' or 'women'
    
    # Enhanced Statistics
    total_trophies = Column(Integer, default=0)
    world_cup_titles = Column(Integer, default=0)
    manager = Column(String)
    captain = Column(String)
    main_rivals = Column(String)
    
    # Detailed Honors (Stored as JSON for flexibility)
    # Example: {"World Cup": 5, "Copa América": 15}
    honors_json = Column(JSON)

    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_football_national_teams_name_lower", func.lower(name)),
    )
