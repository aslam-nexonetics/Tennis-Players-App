from typing import List, Any
from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from app.api import deps
from app.models.user import User
from app.schemas.chat import UserSearchResponse

router = APIRouter()

@router.get("/search", response_model=List[UserSearchResponse])
def search_users(
    q: str = Query(..., min_length=1, description="Search by username, email, or full name"),
    limit: int = Query(20, ge=1, le=50),
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Search registered active users by username, email, or full name.
    Excludes the current logged-in user from search results.
    """
    search_term = f"%{q.strip().lower()}%"
    
    users = db.query(User).filter(
        User.id != current_user.id,
        User.is_active == True,
        or_(
            func.lower(User.username).like(search_term),
            func.lower(User.email).like(search_term),
            func.lower(User.full_name).like(search_term)
        )
    ).limit(limit).all()

    return users
