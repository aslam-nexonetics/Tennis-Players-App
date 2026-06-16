import os
import sys
from dotenv import load_dotenv

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer, TableTennisHistoricalRanking

def main():
    db: Session = SessionLocal()
    try:
        player_count = db.query(TableTennisHistoricalPlayer).count()
        ranking_count = db.query(TableTennisHistoricalRanking).count()
        print(f"Total historical players: {player_count}")
        print(f"Total historical rankings: {ranking_count}")
        
        # Get one player sample
        player = db.query(TableTennisHistoricalPlayer).first()
        if player:
            print(f"\nPlayer sample: ID={player.id}, Name={player.first_name} {player.last_name}, Country={player.country}, Gender={player.gender}")
            # Get their rankings
            rankings = db.query(TableTennisHistoricalRanking).filter(TableTennisHistoricalRanking.player_id == player.id).order_by(TableTennisHistoricalRanking.ranking_year.desc(), TableTennisHistoricalRanking.ranking_month.desc(), TableTennisHistoricalRanking.ranking_date.desc()).limit(5).all()
            print("Rankings:")
            for r in rankings:
                print(f"  - Date: {r.ranking_year}-{r.ranking_month:02d}-{r.ranking_date:02d}, Rank: {r.rank}, Points: {r.points}")
                
        # Find latest ranking date overall
        latest = db.query(TableTennisHistoricalRanking).order_by(TableTennisHistoricalRanking.ranking_year.desc(), TableTennisHistoricalRanking.ranking_month.desc(), TableTennisHistoricalRanking.ranking_date.desc()).first()
        if latest:
            print(f"\nLatest ranking date in DB: {latest.ranking_year}-{latest.ranking_month:02d}-{latest.ranking_date:02d}")
            
    finally:
        db.close()

if __name__ == "__main__":
    main()
