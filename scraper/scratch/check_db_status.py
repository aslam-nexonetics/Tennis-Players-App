import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

with engine.connect() as conn:
    # Get total count
    count_result = conn.execute(text('SELECT count(*) FROM players'))
    total_players = count_result.scalar()
    print(f"Total tennis players in app: {total_players}")

    # Check for specific players
    players_to_find = ['Svyatoslav Gulin', 'Denis Klok']
    for name in players_to_find:
        search_query = text("SELECT * FROM players WHERE name ILIKE :name")
        res = conn.execute(search_query, {"name": f"%{name}%"})
        rows = res.fetchall()
        if rows:
            print(f"Found {name}: {len(rows)} record(s)")
            for row in rows:
                print(f"  - {row}")
        else:
            print(f"NOT FOUND: {name}")
