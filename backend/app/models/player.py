from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class Player(Base):
    __tablename__ = "players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String)
    ranking = Column(Integer, index=True)
    highest_ranking = Column(Integer)
    highest_ranking_date = Column(Date)
    birth_date = Column(Date)
    height = Column(String) # Storing as string to handle formats like "185 cm" or "6'1\""
    weight = Column(String)
    playing_style = Column(String)
    wins = Column(Integer, default=0)
    losses = Column(Integer, default=0)
    turned_pro = Column(String)
    prize_money = Column(String)
    image_url = Column(String)
    gender = Column(String, index=True) # "M" for ATP, "F" for WTA
    source = Column(String)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Explicitly adding indexes if needed, though index=True in Column handles most
    __table_args__ = (
        Index("ix_players_name_lower", func.lower(name)),
    )


class TennisHistoricalPlayer(Base):
    __tablename__ = "tennis_players_historical"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, index=True, nullable=False)
    last_name = Column(String, index=True, nullable=False)
    gender = Column(Integer, nullable=True)  # 0 for Male, 1 for Female
    country = Column(String, nullable=True)
    birth_date = Column(Integer, nullable=True)  # Day of birth (1-31)
    birth_month = Column(Integer, nullable=True)  # Month of birth (1-12)
    birth_year = Column(Integer, nullable=True)  # Year of birth
    picture = Column(String, nullable=True)
    prize_money = Column(String, nullable=True) # Extra field for prize money
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationship to rankings
    rankings = relationship("TennisHistoricalRanking", back_populates="player", cascade="all, delete-orphan")


class TennisHistoricalRanking(Base):
    __tablename__ = "tennis_rankings_historical"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("tennis_players_historical.id", ondelete="CASCADE"), nullable=False, index=True)
    points = Column(Integer, nullable=False)
    rank = Column(Integer, nullable=False)
    ranking_date = Column(Integer, nullable=False)
    ranking_month = Column(Integer, nullable=False)
    ranking_year = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationship to player
    player = relationship("TennisHistoricalPlayer", back_populates="rankings")

    __table_args__ = (
        Index("ix_tennis_rankings_historical_player_date", "player_id", "ranking_year", "ranking_month", "ranking_date", unique=True),
    )

