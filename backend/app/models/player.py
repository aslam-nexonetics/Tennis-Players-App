from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index
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
