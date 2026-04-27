from pydantic import BaseModel, HttpUrl
from datetime import date, datetime
from typing import Optional, List

class PlayerBase(BaseModel):
    name: str
    country: Optional[str] = None
    ranking: Optional[int] = None
    highest_ranking: Optional[int] = None
    highest_ranking_date: Optional[date] = None
    birth_date: Optional[date] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    playing_style: Optional[str] = None
    wins: Optional[int] = 0
    losses: Optional[int] = 0
    image_url: Optional[str] = None
    gender: Optional[str] = None # "M" or "F"
    source: Optional[str] = None

class PlayerCreate(PlayerBase):
    pass

class PlayerUpdate(PlayerBase):
    name: Optional[str] = None

class Player(PlayerBase):
    id: int
    last_updated: datetime

    class Config:
        from_attributes = True

class PlayerList(BaseModel):
    items: List[Player]
    total: int
    page: int
    size: int
