import os
import sys
from dotenv import load_dotenv

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.player import TennisHistoricalPlayer, TennisHistoricalRanking, Player

def main():
    db: Session = SessionLocal()
    try:
        # Find latest ranking date overall for male (gender=0) and female (gender=1)
        latest_male = db.query(TennisHistoricalRanking).join(TennisHistoricalPlayer).filter(TennisHistoricalPlayer.gender == 0).order_by(
            TennisHistoricalRanking.ranking_year.desc(),
            TennisHistoricalRanking.ranking_month.desc(),
            TennisHistoricalRanking.ranking_date.desc()
        ).first()
        
        latest_female = db.query(TennisHistoricalRanking).join(TennisHistoricalPlayer).filter(TennisHistoricalPlayer.gender == 1).order_by(
            TennisHistoricalRanking.ranking_year.desc(),
            TennisHistoricalRanking.ranking_month.desc(),
            TennisHistoricalRanking.ranking_date.desc()
        ).first()
        
        if latest_male:
            print(f"Latest ATP (Male) ranking date in historical DB: {latest_male.ranking_year}-{latest_male.ranking_month:02d}-{latest_male.ranking_date:02d}")
        else:
            print("No ATP rankings found in historical DB.")
            
        if latest_female:
            print(f"Latest WTA (Female) ranking date in historical DB: {latest_female.ranking_year}-{latest_female.ranking_month:02d}-{latest_female.ranking_date:02d}")
        else:
            print("No WTA rankings found in historical DB.")
            
        # Also check the Player table
        print("\nChecking active players:")
        print("Total players in active table:", db.query(Player).count())
        atp_count = db.query(Player).filter(Player.gender == 'M').count()
        wta_count = db.query(Player).filter(Player.gender == 'F').count()
        print(f"ATP active players: {atp_count}, WTA active players: {wta_count}")
        
    finally:
        db.close()

if __name__ == "__main__":
    main()
