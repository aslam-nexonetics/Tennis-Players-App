from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.football_club import FootballClub, FootballClubList
from app.services.football_club_service import FootballClubService
from typing import List

router = APIRouter()

@router.get("/", response_model=FootballClubList)
def get_clubs(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = FootballClubService.get_clubs(db, skip=skip, limit=size, category=category)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/search", response_model=FootballClubList)
def search_clubs(
    q: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = FootballClubService.search_clubs(db, query=q, skip=skip, limit=size, category=category)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/top", response_model=List[FootballClub])
def get_top_clubs(
    limit: int = Query(10, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    return FootballClubService.get_top_clubs(db, limit=limit, category=category)

@router.get("/{id}", response_model=FootballClub)
def get_club(id: int, db: Session = Depends(get_db)):
    club = FootballClubService.get_club(db, club_id=id)
    if not club:
        raise HTTPException(status_code=404, detail="Club not found")
    return club
