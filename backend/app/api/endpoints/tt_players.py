from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.tt_player import TtPlayer, TtPlayerList
from app.services.tt_player_service import TtPlayerService
from typing import List, Optional

router = APIRouter()


@router.get("/", response_model=TtPlayerList)
def get_tt_players(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    gender: Optional[str] = Query(None, description="Filter by gender: 'M' or 'F'"),
    db: Session = Depends(get_db),
):
    skip = (page - 1) * size
    items, total = TtPlayerService.get_players(db, skip=skip, limit=size, gender=gender)
    return {"items": items, "total": total, "page": page, "size": size}


@router.get("/search", response_model=TtPlayerList)
def search_tt_players(
    q: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    gender: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    skip = (page - 1) * size
    items, total = TtPlayerService.search_players(db, query=q, skip=skip, limit=size, gender=gender)
    return {"items": items, "total": total, "page": page, "size": size}


@router.get("/top", response_model=List[TtPlayer])
def get_top_tt_players(
    limit: int = Query(50, ge=1, le=200),
    gender: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    return TtPlayerService.get_top_players(db, limit=limit, gender=gender)


@router.get("/{id}", response_model=TtPlayer)
def get_tt_player(id: int, db: Session = Depends(get_db)):
    player = TtPlayerService.get_player(db, player_id=id)
    if not player:
        raise HTTPException(status_code=404, detail="Table tennis player not found")
    return player
