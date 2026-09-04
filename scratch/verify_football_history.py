import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal
from app.models.football_national_team import FootballNationalTeam, FootballHistoricalTeam, FootballHistoricalRanking
from app.services.football_national_team_service import FootballNationalTeamService

def test():
    db = SessionLocal()
    try:
        total_hist_teams = db.query(FootballHistoricalTeam).count()
        total_hist_rankings = db.query(FootballHistoricalRanking).count()
        print(f"Total Historical Football Teams: {total_hist_teams}")
        print(f"Total Historical Football Rankings: {total_hist_rankings}")

        # Fetch sample teams (e.g. Argentina, France, USA, Japan)
        for name in ["Argentina", "France", "United States", "Brazil"]:
            team = db.query(FootballNationalTeam).filter(FootballNationalTeam.name == name).first()
            if not team:
                print(f"Team '{name}' not found in main table, searching by historical...")
                hist_team = db.query(FootballHistoricalTeam).filter(FootballHistoricalTeam.name == name).first()
                if hist_team:
                    print(f"Found historical team {hist_team.name} (id: {hist_team.id})")
                continue
            
            mapped = FootballNationalTeamService.get_team(db, team.id)
            print(f"\n--- {mapped['name']} ({mapped['category']}) ---")
            print(f"Current Rank: #{mapped['ranking']}")
            print(f"Career High Rank: #{mapped['highest_ranking']} on {mapped['highest_ranking_date']}")
            print(f"History checkpoints count: {len(mapped['ranking_history'] or [])}")
            if mapped['ranking_history']:
                print("First 3 checkpoints:", mapped['ranking_history'][:3])
                print("Last 3 checkpoints:", mapped['ranking_history'][-3:])
    finally:
        db.close()

if __name__ == "__main__":
    test()
