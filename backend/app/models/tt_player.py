from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


class TableTennisPlayer(Base):
    __tablename__ = "table_tennis_players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String)
    ranking = Column(Integer, index=True)
    birth_date = Column(Date)
    weight = Column(String)
    playing_style = Column(String)
    win_percentage = Column(Float)
    image_url = Column(String)
    source = Column(String)
    gender = Column(String)  # 'M' or 'F'
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_tt_players_name_lower", func.lower(name)),
    )


class TableTennisHistoricalPlayer(Base):
    __tablename__ = "tt_players_historical"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, index=True, nullable=False)
    last_name = Column(String, index=True, nullable=False)
    gender = Column(Integer, nullable=True)  # 0 for Male, 1 for Female
    country = Column(String, nullable=True)
    birth_date = Column(Integer, nullable=True)  # Day of birth (1-31)
    birth_month = Column(Integer, nullable=True)  # Month of birth (1-12)
    birth_year = Column(Integer, nullable=True)  # Year of birth
    picture = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationship to rankings
    rankings = relationship("TableTennisHistoricalRanking", back_populates="player", cascade="all, delete-orphan")


class TableTennisHistoricalRanking(Base):
    __tablename__ = "tt_rankings_historical"

    id = Column(Integer, primary_key=True, index=True)
    player_id = Column(Integer, ForeignKey("tt_players_historical.id", ondelete="CASCADE"), nullable=False, index=True)
    points = Column(Integer, nullable=False)
    rank = Column(Integer, nullable=False)
    ranking_date = Column(Integer, nullable=False)
    ranking_month = Column(Integer, nullable=False)
    ranking_year = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationship to player
    player = relationship("TableTennisHistoricalPlayer", back_populates="rankings")

    __table_args__ = (
        Index("ix_tt_rankings_historical_player_date", "player_id", "ranking_year", "ranking_month", "ranking_date", unique=True),
    )

