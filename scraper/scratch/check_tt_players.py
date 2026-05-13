import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
db_url = os.getenv('DATABASE_URL', 'sqlite:///./tennis.db')
engine = create_engine(db_url)
with engine.connect() as conn:
    try:
        result = conn.execute(text('SELECT name, ranking, win_percentage FROM table_tennis_players ORDER BY ranking LIMIT 10'))
        rows = result.fetchall()
        print(f"Found {len(rows)} TT players:")
        for row in rows:
            print(row)
    except Exception as e:
        print(f"Error: {e}")
