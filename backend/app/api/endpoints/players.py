from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.player import Player, PlayerList, H2HResponse
from app.services.player_service import PlayerService
from typing import List, Optional

router = APIRouter()

@router.get("/", response_model=PlayerList)
def get_players(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    gender: Optional[str] = Query(None, pattern="^[MF]$"),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = PlayerService.get_players(db, skip=skip, limit=size, gender=gender)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/search", response_model=PlayerList)
def search_players(
    q: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    gender: Optional[str] = Query(None, pattern="^[MF]$"),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = PlayerService.search_players(db, query=q, skip=skip, limit=size, gender=gender)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/top", response_model=List[Player])
def get_top_players(
    limit: int = Query(10, ge=1, le=100),
    gender: Optional[str] = Query(None, pattern="^[MF]$"),
    db: Session = Depends(get_db)
):
    return PlayerService.get_top_players(db, limit=limit, gender=gender)

@router.get("/{id}", response_model=Player)
def get_player(id: int, db: Session = Depends(get_db)):
    player = PlayerService.get_player(db, player_id=id)
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    return player

@router.get("/h2h/{p1_id}/{p2_id}", response_model=H2HResponse)
def get_h2h(p1_id: int, p2_id: int, db: Session = Depends(get_db)):
    h2h = PlayerService.get_h2h(db, p1_id, p2_id)
    if not h2h:
        raise HTTPException(status_code=404, detail="Players not found")
    return h2h
