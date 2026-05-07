import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

with engine.connect() as conn:
    search_query = text("SELECT name, ranking FROM players WHERE name ILIKE :name")
    for name in ['Gulin', 'Klok']:
        res = conn.execute(search_query, {"name": f"%{name}%"})
        rows = res.fetchall()
        print(f"Search results for {name}:")
        for row in rows:
            print(f"  - {row[0]} (Rank {row[1]})")
