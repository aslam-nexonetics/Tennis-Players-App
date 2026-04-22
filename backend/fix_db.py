import sqlite3
import os

db_path = "/home/nexonetics/nexonetics/tennis_app/backend/tennis.db"

if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("DROP TABLE football_players")
        print("Dropped 'football_players' table successfully.")
        conn.commit()
    except sqlite3.OperationalError as e:
        print(f"Error: {e}")
    finally:
        conn.close()
else:
    print(f"Database not found at {db_path}")
