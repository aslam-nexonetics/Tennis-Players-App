from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index
from sqlalchemy.sql import func
from app.db.session import Base


class TableTennisPlayer(Base):
    __tablename__ = "table_tennis_players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    country = Column(String)
    ranking = Column(Integer, index=True)
    highest_ranking = Column(Integer)
    highest_ranking_date = Column(Date)
    birth_date = Column(Date)
    height = Column(String)
    weight = Column(String)
    playing_style = Column(String)
    wins = Column(Integer, default=0)
    losses = Column(Integer, default=0)
    image_url = Column(String)
    source = Column(String)
    gender = Column(String)  # 'M' or 'F'
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_tt_players_name_lower", func.lower(name)),
    )
