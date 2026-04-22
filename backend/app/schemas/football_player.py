from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List

class FootballPlayerBase(BaseModel):
    name: str
    country: Optional[str] = None
    ranking: Optional[int] = None
    current_club: Optional[str] = None
    position: Optional[str] = None
    preferred_foot: Optional[str] = None
    jersey_number: Optional[int] = None
    contract_until: Optional[str] = None
    rating: Optional[int] = None
    international_caps: Optional[int] = 0
    international_goals: Optional[int] = 0
    birth_date: Optional[date] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    market_value: Optional[str] = None
    goals: Optional[int] = 0
    assists: Optional[int] = 0
    image_url: Optional[str] = None
    source: Optional[str] = None

class FootballPlayerCreate(FootballPlayerBase):
    pass

class FootballPlayerUpdate(FootballPlayerBase):
    name: Optional[str] = None

class FootballPlayer(FootballPlayerBase):
    id: int
    last_updated: datetime

    class Config:
        from_attributes = True

class FootballPlayerList(BaseModel):
    items: List[FootballPlayer]
    total: int
    page: int
    size: int
