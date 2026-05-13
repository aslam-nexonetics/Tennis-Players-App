from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Index
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
