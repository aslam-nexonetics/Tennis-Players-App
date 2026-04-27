import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Load environment from the scraper directory
load_dotenv()

db_url = os.getenv('DATABASE_URL')
print(f"Connecting to: {db_url[:20]}...")

engine = create_engine(db_url)
with engine.connect() as conn:
    conn.execute(text('DROP TABLE IF EXISTS football_clubs CASCADE'))
    conn.commit()
    print('Table football_clubs dropped successfully from Neon.')
