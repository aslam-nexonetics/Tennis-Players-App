import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)

with engine.connect() as conn:
    result = conn.execute(text('SELECT gender, count(*) FROM players GROUP BY gender'))
    for row in result:
        print(f"Gender {row[0]}: {row[1]} players")
