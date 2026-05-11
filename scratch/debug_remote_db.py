
import sqlalchemy
from sqlalchemy import create_engine, text

DATABASE_URL = "postgresql://neondb_owner:npg_48uqktSjVLpR@ep-damp-resonance-anwqigab.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require"
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    query = text("SELECT name, world_cup_titles, honors_json FROM football_national_teams WHERE name IN ('Brazil', 'Argentina', 'Germany', 'Spain')")
    result = conn.execute(query)
    
    for row in result:
        print(f"Team: {row[0]}")
        print(f"  WC: {row[1]}")
        print(f"  Honors (raw): {row[2]}")
        print(f"  Honors type: {type(row[2])}")
