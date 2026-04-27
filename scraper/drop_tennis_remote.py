import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)
with engine.connect() as conn:
    conn.execute(text('DROP TABLE IF EXISTS players CASCADE'))
    conn.commit()
    print('Tennis table dropped successfully.')
