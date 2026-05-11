
import sqlalchemy
from sqlalchemy import create_engine, text

DATABASE_URL = "postgresql://neondb_owner:npg_48uqktSjVLpR@ep-damp-resonance-anwqigab.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require"
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    query = text("SELECT name, world_cup_titles, honors_json FROM football_national_teams WHERE name IN ('Egypt', 'Mexico', 'Japan', 'USA')")
    result = conn.execute(query)
    
    print(f"{'Team':20} | {'WC':2} | {'Honors'}")
    print("-" * 60)
    for row in result:
        print(f"{row[0]:20} | {row[1]:2} | {row[2]}")
