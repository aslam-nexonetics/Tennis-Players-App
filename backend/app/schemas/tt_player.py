from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List


class TtPlayerBase(BaseModel):
    name: str
    country: Optional[str] = None
    ranking: Optional[int] = None
    birth_date: Optional[date] = None
    weight: Optional[str] = None
    playing_style: Optional[str] = None
    wins: Optional[int] = 0
    losses: Optional[int] = 0
    image_url: Optional[str] = None
    source: Optional[str] = None
    gender: Optional[str] = None


class TtPlayerCreate(TtPlayerBase):
    pass


class TtPlayerUpdate(TtPlayerBase):
    name: Optional[str] = None


class TtPlayer(TtPlayerBase):
    id: int
    last_updated: Optional[datetime] = None

    class Config:
        from_attributes = True


class TtPlayerList(BaseModel):
    items: List[TtPlayer]
    total: int
    page: int
    size: int
