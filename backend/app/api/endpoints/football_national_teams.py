from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.football_national_team import FootballNationalTeam, FootballNationalTeamList
from app.services.football_national_team_service import FootballNationalTeamService
from typing import List

router = APIRouter()

@router.get("/", response_model=FootballNationalTeamList)
def get_teams(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = FootballNationalTeamService.get_teams(db, skip=skip, limit=size, category=category)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/search", response_model=FootballNationalTeamList)
def search_teams(
    q: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * size
    items, total = FootballNationalTeamService.search_teams(db, query=q, skip=skip, limit=size, category=category)
    return {"items": items, "total": total, "page": page, "size": size}

@router.get("/top", response_model=List[FootballNationalTeam])
def get_top_teams(
    limit: int = Query(10, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    return FootballNationalTeamService.get_top_teams(db, limit=limit, category=category)

@router.get("/{id}", response_model=FootballNationalTeam)
def get_team(id: int, db: Session = Depends(get_db)):
    team = FootballNationalTeamService.get_team(db, team_id=id)
    if not team:
        raise HTTPException(status_code=404, detail="National Team not found")
    return team
