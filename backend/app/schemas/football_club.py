from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict

class FootballClubBase(BaseModel):
    name: str
    country: Optional[str] = None
    league: Optional[str] = None
    founded_year: Optional[int] = None
    stadium: Optional[str] = None
    capacity: Optional[int] = None
    manager: Optional[str] = None
    nickname: Optional[str] = None
    image_url: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    ranking: Optional[int] = None
    
    # Enhanced Statistics
    total_trophies: Optional[int] = 0
    market_value: Optional[str] = None
    league_position: Optional[int] = None
    domestic_ranking: Optional[int] = None
    captain: Optional[str] = None
    owner: Optional[str] = None
    main_rivals: Optional[str] = None
    average_attendance: Optional[int] = None
    
    # Detailed Honors
    honors_json: Optional[Dict[str, int]] = None

class FootballClubCreate(FootballClubBase):
    pass

class FootballClubUpdate(FootballClubBase):
    name: Optional[str] = None

class FootballClub(FootballClubBase):
    id: int
    last_updated: datetime

    class Config:
        from_attributes = True

class FootballClubList(BaseModel):
    items: List[FootballClub]
    total: int
    page: int
    size: int
