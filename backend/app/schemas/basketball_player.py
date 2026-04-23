from pydantic import BaseModel, ConfigDict
from datetime import date, datetime
from typing import Optional, List


class BasketballRankingHistoryBase(BaseModel):
    ranking: int
    date: datetime

class BasketballRankingHistoryCreate(BasketballRankingHistoryBase):
    player_id: int

class BasketballRankingHistory(BasketballRankingHistoryBase):
    id: int
    player_id: int

    class Config:
        from_attributes = True

class BasketballPlayerBase(BaseModel):
    name: str
    country: Optional[str] = None
    ranking: Optional[int] = None
    team: Optional[str] = None
    position: Optional[str] = None
    jersey_number: Optional[int] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    birth_date: Optional[date] = None
    college: Optional[str] = None
    draft_year: Optional[int] = None
    draft_pick: Optional[int] = None
    
    # Stats
    ppg: Optional[float] = 0.0
    rpg: Optional[float] = 0.0
    apg: Optional[float] = 0.0
    spg: Optional[float] = 0.0
    bpg: Optional[float] = 0.0
    fg_pct: Optional[float] = 0.0
    three_pt_pct: Optional[float] = None
    ft_pct: Optional[float] = None
    ranking_history: List[BasketballRankingHistory] = []
    
    image_url: Optional[str] = None
    source: Optional[str] = None


class BasketballPlayerCreate(BasketballPlayerBase):
    pass


class BasketballPlayer(BasketballPlayerBase):
    id: int
    last_updated: datetime

    model_config = ConfigDict(from_attributes=True)


class BasketballPlayerList(BaseModel):
    items: List[BasketballPlayer]
    total: int
    page: int
    size: int
