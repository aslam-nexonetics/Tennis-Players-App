import os
import sys
import json
import csv
from datetime import date, datetime

# Add backend directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from dotenv import load_dotenv
load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env')))

from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.player import Player
from app.models.tt_player import TableTennisPlayer, TableTennisHistoricalPlayer
from app.models.football_national_team import FootballNationalTeam
from app.models.basketball_club import BasketballClub


class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)


def row_to_dict(row):
    d = {}
    for column in row.__table__.columns:
        d[column.name] = getattr(row, column.name)
    return d


def map_all_historical_tt_players(db: Session):
    """
    Returns (player_list, histories_dict).
    - player_list: lightweight list of player dicts WITHOUT ranking_history
    - histories_dict: {str(player_id): [{ranking, date}, ...]} sampled to 20 points
    """
    print("  Fetching legacy players...")
    legacy_players = db.query(TableTennisPlayer).all()

    # Build case-insensitive lookup. Legacy uses mixed CAPS like "Tomokazu HARIMOTO".
    legacy_by_name_ci = {lp.name.lower(): lp for lp in legacy_players}
    # Also index by reversed word order so "Wang Chuqin" matches "WANG Chuqin"
    legacy_by_reversed_ci = {}
    for lp in legacy_players:
        parts = lp.name.split()
        if len(parts) >= 2:
            rev = ' '.join(reversed(parts))
            legacy_by_reversed_ci[rev.lower()] = lp

    print("  Fetching historical players...")
    players = db.query(TableTennisHistoricalPlayer).all()

    print("  Fetching all historical rankings (ordered via raw SQL)...")
    result = db.execute(text(
        "SELECT player_id, rank, points, ranking_year, ranking_month, ranking_date "
        "FROM tt_rankings_historical "
        "ORDER BY ranking_year ASC, ranking_month ASC, ranking_date ASC"
    ))

    print("  Grouping rankings by player in-memory...")
    rankings_by_player = {}
    for row in result:
        pid = row[0]
        if pid not in rankings_by_player:
            rankings_by_player[pid] = []
        rankings_by_player[pid].append(row)

    print("  Fetching latest global ranking dates per gender...")
    latest_m = db.execute(text("""
        SELECT r.ranking_year, r.ranking_month, r.ranking_date 
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 0
        ORDER BY r.ranking_year DESC, r.ranking_month DESC, r.ranking_date DESC
        LIMIT 1
    """)).fetchone()
    latest_f = db.execute(text("""
        SELECT r.ranking_year, r.ranking_month, r.ranking_date 
        FROM tt_rankings_historical r
        JOIN tt_players_historical p ON r.player_id = p.id
        WHERE p.gender = 1
        ORDER BY r.ranking_year DESC, r.ranking_month DESC, r.ranking_date DESC
        LIMIT 1
    """)).fetchone()

    print("  Mapping players...")
    player_list = []
    histories_dict = {}
    matched_count = 0

    for p in players:
        p_rankings = rankings_by_player.get(p.id, [])

        # Assign current rank ONLY if player was ranked on the latest global ranking date for their gender
        latest_r = p_rankings[-1] if p_rankings else None
        target_date = latest_m if p.gender == 0 else latest_f
        
        rank = None
        if latest_r and latest_r[1] > 0 and target_date:
            if (latest_r[3], latest_r[4], latest_r[5]) == (target_date[0], target_date[1], target_date[2]):
                rank = latest_r[1]

        # Build name variants for matching
        full_name = f"{p.first_name} {p.last_name}"
        reversed_name = f"{p.last_name} {p.first_name}"
        full_name_lower = full_name.lower()
        reversed_lower = reversed_name.lower()

        # Case-insensitive name match against legacy table
        style = None
        win_pct = None
        weight = None
        legacy_image = None

        legacy_p = (
            legacy_by_name_ci.get(full_name_lower) or
            legacy_by_name_ci.get(reversed_lower) or
            legacy_by_reversed_ci.get(full_name_lower) or
            legacy_by_reversed_ci.get(reversed_lower)
        )
        if legacy_p:
            style = legacy_p.playing_style
            win_pct = legacy_p.win_percentage
            weight = legacy_p.weight
            legacy_image = legacy_p.image_url
            matched_count += 1

        # Prefer historical Wikipedia picture; fallback to legacy WTT headshot
        image_url = p.picture or legacy_image

        # Birth date
        b_date = None
        if p.birth_year and p.birth_month and p.birth_date:
            try:
                b_date = date(p.birth_year, p.birth_month, p.birth_date)
            except ValueError:
                pass

        # Career high rank (valid ranks only, rank > 0)
        career_high_rank = None
        career_high_date = None
        valid_rankings = [r for r in p_rankings if r[1] > 0]
        if valid_rankings:
            ch_record = min(valid_rankings, key=lambda r: (r[1], r[3], r[4], r[5]))
            career_high_rank = ch_record[1]
            try:
                career_high_date = date(ch_record[3], ch_record[4], ch_record[5])
            except ValueError:
                pass

        # Sample up to 20 ranking points for the history file
        sampled = []
        if valid_rankings:
            n = len(valid_rankings)
            if n <= 20:
                sampled = valid_rankings
            else:
                for i in range(20):
                    idx = int(i * (n - 1) / 19)
                    sampled.append(valid_rankings[idx])

        history_points = []
        for h in sampled:
            try:
                h_date = date(h[3], h[4], h[5])
                history_points.append({
                    "ranking": h[1],
                    "date": h_date.isoformat()
                })
            except ValueError:
                pass

        gender_str = 'M' if p.gender == 0 else ('F' if p.gender == 1 else None)

        # Lightweight player entry (no ranking_history embedded)
        player_list.append({
            "id": p.id,
            "name": full_name,
            "country": p.country,
            "ranking": rank,
            "birth_date": b_date.isoformat() if b_date else None,
            "weight": weight,
            "playing_style": style,
            "win_percentage": win_pct,
            "image_url": image_url,
            "source": "ITTF Database",
            "gender": gender_str,
            "last_updated": p.last_updated.isoformat() if p.last_updated else None,
            "career_high_rank": career_high_rank,
            "career_high_date": career_high_date.isoformat() if career_high_date else None
        })

        # Histories stored separately keyed by string ID
        if history_points:
            histories_dict[str(p.id)] = history_points

    print(f"  Legacy match rate: {matched_count}/{len(players)} players enriched with style/image")
    return player_list, histories_dict


def save_json(data, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, cls=DateTimeEncoder, separators=(',', ':'), ensure_ascii=False)


def export_simple_table(db, model, name, json_path, csv_path):
    print(f"Exporting {name}...")
    rows = db.query(model).all()
    dicts = [row_to_dict(r) for r in rows]

    save_json(dicts, json_path)
    print(f"  Saved {json_path} ({len(dicts)} rows, {os.path.getsize(json_path)//1024} KB)")

    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    if dicts:
        headers = list(dicts[0].keys())
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            for d in dicts:
                row_data = {}
                for k, v in d.items():
                    if isinstance(v, (datetime, date)):
                        row_data[k] = v.isoformat()
                    elif isinstance(v, (dict, list)):
                        row_data[k] = json.dumps(v, ensure_ascii=False)
                    else:
                        row_data[k] = v
                writer.writerow(row_data)
        print(f"  Saved CSV to {csv_path}")


def export_tt_players(db, json_dir, csv_dir):
    print("Exporting Table Tennis Players (split: list + histories)...")
    player_list, histories_dict = map_all_historical_tt_players(db)

    # 1. Lightweight player list (no ranking_history)
    list_path = os.path.join(json_dir, 'tt_players.json')
    save_json(player_list, list_path)
    print(f"  Saved tt_players.json: {os.path.getsize(list_path)//1024} KB ({len(player_list)} players)")

    # 2. Compact histories dict {id: [{ranking, date}, ...]}
    hist_path = os.path.join(json_dir, 'tt_player_histories.json')
    save_json(histories_dict, hist_path)
    print(f"  Saved tt_player_histories.json: {os.path.getsize(hist_path)//1024} KB ({len(histories_dict)} players with history)")

    # 3. Stats summary
    ranked = [p for p in player_list if p['ranking'] and p['ranking'] > 0]
    with_img = [p for p in player_list if p['image_url']]
    print(f"  Players with valid ranking: {len(ranked)}")
    print(f"  Players with image: {len(with_img)}")

    # 4. CSV backup
    csv_path = os.path.join(csv_dir, 'tt_players.csv')
    os.makedirs(csv_dir, exist_ok=True)
    if player_list:
        headers = list(player_list[0].keys()) + ['ranking_history']
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            for d in player_list:
                row_data = dict(d)
                row_data['ranking_history'] = json.dumps(
                    histories_dict.get(str(d['id']), []), ensure_ascii=False
                )
                writer.writerow(row_data)
        print(f"  Saved CSV backup: {csv_path}")


def main():
    db: Session = SessionLocal()
    try:
        json_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'frontend', 'assets', 'data'))
        csv_dir  = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scratch'))

        # Tennis Players
        export_simple_table(db, Player, "Tennis Players",
                            os.path.join(json_dir, 'players.json'),
                            os.path.join(csv_dir, 'players.csv'))

        # Table Tennis — split export
        export_tt_players(db, json_dir, csv_dir)

        # Football
        export_simple_table(db, FootballNationalTeam, "Football National Teams",
                            os.path.join(json_dir, 'football_national_teams.json'),
                            os.path.join(csv_dir, 'football_national_teams.csv'))

        # Basketball
        export_simple_table(db, BasketballClub, "Basketball Clubs",
                            os.path.join(json_dir, 'basketball_clubs.json'),
                            os.path.join(csv_dir, 'basketball_clubs.csv'))

        print("\nAll tables successfully exported.")
    except Exception as e:
        print(f"Error during export: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    main()
