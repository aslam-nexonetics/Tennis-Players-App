import sys
import os
from datetime import date

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal, engine, Base
from app.models.football_national_team import FootballNationalTeam, FootballHistoricalTeam, FootballHistoricalRanking
from sqlalchemy.orm import Session
from scraper.utils.logger import log

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

def save_football_national_team(team_data: dict):
    db = SessionLocal()
    try:
        existing = db.query(FootballNationalTeam).filter(
            FootballNationalTeam.name == team_data['name'],
            FootballNationalTeam.category == team_data.get('category', 'men')
        ).first()
        
        if existing:
            # Update existing record
            for key, value in team_data.items():
                if value is not None:
                    setattr(existing, key, value)
            log.debug(f"Updated National Team: {team_data['name']}")
        else:
            # Create new record
            new_team = FootballNationalTeam(**team_data)
            db.add(new_team)
            log.info(f"Added new National Team: {team_data['name']}")

        # Sync/Create FootballHistoricalTeam
        hist_team = db.query(FootballHistoricalTeam).filter(
            FootballHistoricalTeam.name == team_data['name'],
            FootballHistoricalTeam.category == team_data.get('category', 'men')
        ).first()
        if not hist_team:
            hist_team = FootballHistoricalTeam(
                name=team_data['name'],
                country=team_data.get('country', team_data['name']),
                confederation=team_data.get('confederation'),
                category=team_data.get('category', 'men'),
                picture=team_data.get('image_url')
            )
            db.add(hist_team)
            db.flush()

        rank = team_data.get('ranking')
        if rank and rank < 999:
            today = date.today()
            existing_r = db.query(FootballHistoricalRanking).filter(
                FootballHistoricalRanking.team_id == hist_team.id,
                FootballHistoricalRanking.ranking_year == today.year,
                FootballHistoricalRanking.ranking_month == today.month,
                FootballHistoricalRanking.ranking_date == today.day
            ).first()
            if not existing_r:
                points = float(team_data.get('points', 0.0))
                db.add(FootballHistoricalRanking(
                    team_id=hist_team.id,
                    points=points,
                    rank=rank,
                    ranking_date=today.day,
                    ranking_month=today.month,
                    ranking_year=today.year
                ))
        
        db.commit()
    except Exception as e:
        db.rollback()
        log.error(f"Failed to save national team {team_data.get('name')}: {e}")
    finally:
        db.close()

