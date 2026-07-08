import sys
import os
import csv
from datetime import datetime

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer

def main():
    db = SessionLocal()
    csv_path = os.path.join(project_root, 'scratch', 'ttplayersages.csv')
    
    current_year = 2026  # Based on current local time in metadata (June 30, 2026)
    print(f"Current year used for age calculation: {current_year}")
    
    try:
        with open(csv_path, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row['name'].strip()
                age = int(row['age'].strip())
                
                # Calculate birth year (e.g. 2026 - 24 = 2002)
                birth_year = current_year - age
                birth_month = 1
                birth_date = 1
                
                print(f"\nProcessing '{name}' (age: {age}) -> calculated DOB: {birth_year:04d}-{birth_month:02d}-{birth_date:02d}")
                
                # Query players matching first_name + last_name or last_name + first_name
                players = db.query(TableTennisHistoricalPlayer).filter(
                    (TableTennisHistoricalPlayer.first_name + " " + TableTennisHistoricalPlayer.last_name).ilike(name) |
                    (TableTennisHistoricalPlayer.last_name + " " + TableTennisHistoricalPlayer.first_name).ilike(name)
                ).all()
                
                if not players:
                    print(f"  Warning: No matching player found in DB for '{name}'")
                    continue
                
                for player in players:
                    print(f"  Updating Player: ID={player.id}, Name={player.first_name} {player.last_name}")
                    print(f"    Old DOB: {player.birth_year}-{player.birth_month}-{player.birth_date}")
                    
                    player.birth_year = birth_year
                    player.birth_month = birth_month
                    player.birth_date = birth_date
                    
                    print(f"    New DOB: {player.birth_year}-{player.birth_month}-{player.birth_date}")
            
            # Commit the updates
            db.commit()
            print("\nDatabase changes committed successfully.")
            
    except Exception as e:
        db.rollback()
        print(f"Error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    main()
