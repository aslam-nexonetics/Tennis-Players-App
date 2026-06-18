from pydantic import BaseModel, HttpUrl
from datetime import date, datetime
from typing import Optional, List, Dict

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
    turned_pro: Optional[str] = None
    prize_money: Optional[str] = None
    image_url: Optional[str] = None
    gender: Optional[str] = None # "M" or "F"
    source: Optional[str] = None

class PlayerCreate(PlayerBase):
    pass

class PlayerUpdate(PlayerBase):
    name: Optional[str] = None

class PlayerRankingHistoryPoint(BaseModel):
    ranking: int
    date: date

class Player(PlayerBase):
    id: int
    last_updated: Optional[datetime] = None
    ranking_history: Optional[List[PlayerRankingHistoryPoint]] = None
    career_high_rank: Optional[int] = None
    career_high_date: Optional[date] = None

    class Config:
        from_attributes = True

class PlayerList(BaseModel):
    items: List[Player]
    total: int
    page: int
    size: int

# Head-to-Head Schemas
class H2HMatch(BaseModel):
    year: int
    event: str
    round: str
    surface: str # Hard, Clay, Grass
    score: str
    winner_id: int
    winner_name: str

class H2HStats(BaseModel):
    matches_played: int
    player1_wins: int
    player2_wins: int
    player1_win_pct: float
    player2_win_pct: float
    hard_court_wins: Dict[int, int] # player_id -> wins
    clay_court_wins: Dict[int, int]
    grass_court_wins: Dict[int, int]
    last_match: Optional[H2HMatch] = None

class H2HResponse(BaseModel):
    player1: Player
    player2: Player
    stats: H2HStats
    history: List[H2HMatch]
