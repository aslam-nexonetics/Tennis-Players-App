
import sqlalchemy
from sqlalchemy import create_engine, text

DATABASE_URL = "postgresql://neondb_owner:npg_48uqktSjVLpR@ep-damp-resonance-anwqigab.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require"
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    query = text("SELECT id, name, category, world_cup_titles, honors_json FROM football_national_teams WHERE name IN ('Brazil', 'Argentina', 'Germany', 'Spain')")
    result = conn.execute(query)
    
    for row in result:
        print(f"ID: {row[0]} | Team: {row[1]} | Cat: {row[2]} | WC: {row[3]} | Honors: {row[4]}")
