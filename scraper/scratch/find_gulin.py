import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

with engine.connect() as conn:
    print("Players around rank 526:")
    res = conn.execute(text("SELECT name, ranking FROM players WHERE ranking BETWEEN 510 AND 540 ORDER BY ranking"))
    for row in res:
        print(f"  - {row[0]} (Rank {row[1]})")
    
    print("\nSearch for 'Gulin' in all players:")
    res = conn.execute(text("SELECT name, ranking FROM players WHERE name ILIKE '%Gulin%'"))
    for row in res:
        print(f"  - {row[0]} (Rank {row[1]})")
