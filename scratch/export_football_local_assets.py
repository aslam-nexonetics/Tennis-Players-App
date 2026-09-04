import os
import sys
import json

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import SessionLocal
from app.models.football_national_team import FootballNationalTeam
from app.services.football_national_team_service import FootballNationalTeamService

OUT_DIR = os.path.join(project_root, 'frontend', 'assets', 'data')
os.makedirs(OUT_DIR, exist_ok=True)

def export_local():
    db = SessionLocal()
    try:
        teams = db.query(FootballNationalTeam).all()
        mapped_list = []
        histories = {}

        for t in teams:
            detail = FootballNationalTeamService.get_team(db, t.id)
            if not detail:
                continue
            
            # Form JSON serializable item
            item = {
                "id": detail["id"],
                "name": detail["name"],
                "country": detail["country"],
                "confederation": detail["confederation"],
                "founded_year": detail["founded_year"],
                "stadium": detail["stadium"],
                "manager": detail["manager"],
                "nickname": detail["nickname"],
                "image_url": detail["image_url"],
                "website": detail["website"],
                "description": detail["description"],
                "ranking": detail["ranking"],
                "category": detail["category"],
                "total_trophies": detail["total_trophies"],
                "world_cup_titles": detail["world_cup_titles"],
                "captain": detail["captain"],
                "main_rivals": detail["main_rivals"],
                "honors_json": detail["honors_json"],
                "highest_ranking": detail["highest_ranking"],
                "highest_ranking_date": detail["highest_ranking_date"].isoformat() if detail["highest_ranking_date"] else None,
                "last_updated": detail["last_updated"].isoformat() if detail["last_updated"] else None
            }
            mapped_list.append(item)

            if detail["ranking_history"]:
                formatted_history = []
                for h in detail["ranking_history"]:
                    formatted_history.append({
                        "ranking": h["ranking"],
                        "date": h["date"].isoformat() if hasattr(h["date"], "isoformat") else str(h["date"])
                    })
                histories[str(t.id)] = formatted_history

        # Write files
        teams_path = os.path.join(OUT_DIR, 'football_national_teams.json')
        with open(teams_path, 'w', encoding='utf-8') as f:
            json.dump(mapped_list, f, ensure_ascii=False, indent=2)
        print(f"Exported {len(mapped_list)} national teams to {teams_path}")

        histories_path = os.path.join(OUT_DIR, 'football_team_histories.json')
        with open(histories_path, 'w', encoding='utf-8') as f:
            json.dump(histories, f, ensure_ascii=False, indent=2)
        print(f"Exported {len(histories)} team histories to {histories_path}")

    finally:
        db.close()

if __name__ == "__main__":
    export_local()
