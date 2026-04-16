from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.player import Player, PlayerList
from app.services.player_service import PlayerService
from typing import List

router = APIRouter()

@router.get("/", response_model=PlayerList)
def get_players(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = PlayerService.get_players(db, skip=skip, limit=size)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/search", response_model=PlayerList)
def search_players(
    q: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = PlayerService.search_players(db, query=q, skip=skip, limit=size)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/top", response_model=List[Player])
def get_top_players(
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    return PlayerService.get_top_players(db, limit=limit)

@router.get("/{id}", response_model=Player)
def get_player(id: int, db: Session = Depends(get_db)):
    player = PlayerService.get_player(db, player_id=id)
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    return player
