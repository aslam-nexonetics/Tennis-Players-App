from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict

class FootballNationalTeamBase(BaseModel):
    name: str
    country: Optional[str] = None
    confederation: Optional[str] = None
    founded_year: Optional[int] = None
    stadium: Optional[str] = None
    manager: Optional[str] = None
    nickname: Optional[str] = None
    image_url: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    ranking: Optional[int] = None
    category: Optional[str] = "men"
    
    # Enhanced Statistics
    total_trophies: Optional[int] = 0
    world_cup_titles: Optional[int] = 0
    captain: Optional[str] = None
    main_rivals: Optional[str] = None
    
    # Detailed Honors
    honors_json: Optional[Dict[str, int]] = None

class FootballNationalTeamCreate(FootballNationalTeamBase):
    pass

class FootballNationalTeamUpdate(FootballNationalTeamBase):
    name: Optional[str] = None

class FootballNationalTeam(FootballNationalTeamBase):
    id: int
    last_updated: datetime

    class Config:
        from_attributes = True

class FootballNationalTeamList(BaseModel):
    items: List[FootballNationalTeam]
    total: int
    page: int
    size: int
