import os
import sys
from dotenv import load_dotenv

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalRanking, TableTennisHistoricalPlayer

def main():
    db = SessionLocal()
    try:
        # Let's inspect Liang Jingkun (id=14 or search by name)
        liang = db.query(TableTennisHistoricalPlayer).filter(
            TableTennisHistoricalPlayer.last_name.ilike("%Jingkun%")
        ).first()
        
        if liang:
            print(f"Player: {liang.first_name} {liang.last_name} (ID: {liang.id})")
            rankings = db.query(TableTennisHistoricalRanking).filter(
                TableTennisHistoricalRanking.player_id == liang.id
            ).order_by(
                TableTennisHistoricalRanking.ranking_year.desc(),
                TableTennisHistoricalRanking.ranking_month.desc(),
                TableTennisHistoricalRanking.ranking_date.desc()
            ).all()
            print(f"Total ranking records in DB: {len(rankings)}")
            print("Latest 5 rankings:")
            for r in rankings[:5]:
                print(f"  Date: {r.ranking_year}-{r.ranking_month}-{r.ranking_date}, Rank: {r.rank}")
            print("Oldest 5 rankings:")
            for r in rankings[-5:]:
                print(f"  Date: {r.ranking_year}-{r.ranking_month}-{r.ranking_date}, Rank: {r.rank}")
                
            # Find career high
            best_rank_record = db.query(TableTennisHistoricalRanking).filter(
                TableTennisHistoricalRanking.player_id == liang.id
            ).order_by(TableTennisHistoricalRanking.rank.asc()).first()
            if best_rank_record:
                print(f"Career High: Rank {best_rank_record.rank} on {best_rank_record.ranking_year}-{best_rank_record.ranking_month}-{best_rank_record.ranking_date}")
        else:
            print("Liang Jingkun not found")
            
        # Let's look at another player Lin Yun-Ju
        lin = db.query(TableTennisHistoricalPlayer).filter(
            TableTennisHistoricalPlayer.last_name.ilike("%Yun-Ju%") | TableTennisHistoricalPlayer.first_name.ilike("%Lin%")
        ).first()
        if lin:
            print(f"\nPlayer: {lin.first_name} {lin.last_name} (ID: {lin.id})")
            rankings = db.query(TableTennisHistoricalRanking).filter(
                TableTennisHistoricalRanking.player_id == lin.id
            ).order_by(
                TableTennisHistoricalRanking.ranking_year.desc(),
                TableTennisHistoricalRanking.ranking_month.desc(),
                TableTennisHistoricalRanking.ranking_date.desc()
            ).all()
            print(f"Total ranking records in DB: {len(rankings)}")
            print("Latest 5 rankings:")
            for r in rankings[:5]:
                print(f"  Date: {r.ranking_year}-{r.ranking_month}-{r.ranking_date}, Rank: {r.rank}")
            print("Oldest 5 rankings:")
            for r in rankings[-5:]:
                print(f"  Date: {r.ranking_year}-{r.ranking_month}-{r.ranking_date}, Rank: {r.rank}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
