from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


class BasketballPlayer(Base):
    __tablename__ = "basketball_players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String)
    ranking = Column(Integer, index=True) # Overall ranking/rating
    team = Column(String)
    position = Column(String)
    jersey_number = Column(Integer)
    height = Column(String)
    weight = Column(String)
    birth_date = Column(Date)
    college = Column(String)
    draft_year = Column(Integer)
    draft_pick = Column(Integer)
    
    # Career/Season Stats
    ppg = Column(Float, default=0.0) # Points per game
    rpg = Column(Float, default=0.0) # Rebounds per game
    apg = Column(Float, default=0.0) # Assists per game
    spg = Column(Float, default=0.0) # Steals per game
    bpg = Column(Float, default=0.0) # Blocks per game
    fg_pct = Column(Float, default=0.0) # Field Goal %
    three_pt_pct = Column(Float, default=0.0) # 3-Point %
    ft_pct = Column(Float, default=0.0) # Free Throw %
    
    image_url = Column(String)
    source = Column(String)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    ranking_history = relationship("BasketballRankingHistory", back_populates="player", cascade="all, delete-orphan")

class BasketballRankingHistory(Base):
    __tablename__ = "basketball_ranking_history"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("basketball_players.id"))
    ranking = Column(Integer, nullable=False)
    date = Column(DateTime(timezone=True), server_default=func.now())

    player = relationship("BasketballPlayer", back_populates="ranking_history")

    __table_args__ = (
        Index("ix_basketball_players_name_lower", func.lower(name)),
    )
