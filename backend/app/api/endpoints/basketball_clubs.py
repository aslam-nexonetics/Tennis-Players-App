from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.session import get_db
from app.models.basketball_club import BasketballClub as BasketballClubModel
from app.schemas.basketball_club import BasketballClub, BasketballClubList
from sqlalchemy import func

router = APIRouter()

@router.get("/search", response_model=BasketballClubList)
def search_clubs(
    q: str = "",
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(BasketballClubModel)
    if q:
        query = query.filter(
            (func.lower(BasketballClubModel.name).contains(q.lower())) |
            (func.lower(BasketballClubModel.city).contains(q.lower()))
        )
    
    total = query.count()
    items = query.offset((page - 1) * size).limit(size).all()
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "size": size
    }

@router.get("/top", response_model=List[BasketballClub])
def get_top_clubs(limit: int = 50, db: Session = Depends(get_db)):
    return db.query(BasketballClubModel).order_by(BasketballClubModel.ranking.asc()).limit(limit).all()

@router.get("/{club_id}", response_model=BasketballClub)
def get_club(club_id: int, db: Session = Depends(get_db)):
    club = db.query(BasketballClubModel).filter(BasketballClubModel.id == club_id).first()
    if not club:
        raise HTTPException(status_code=404, detail="Basketball club not found")
    return club
