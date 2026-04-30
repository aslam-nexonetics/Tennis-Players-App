import sys
import os
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import engine
from sqlalchemy import text

def migrate():
    with engine.connect() as conn:
        print("Migrating players table...")
        try:
            conn.execute(text("ALTER TABLE players ADD COLUMN titles INTEGER DEFAULT 0"))
            print("Added titles")
        except Exception as e: print(f"titles already exists or error: {e}")
        
        try:
            conn.execute(text("ALTER TABLE players ADD COLUMN turned_pro VARCHAR"))
            print("Added turned_pro")
        except Exception as e: print(f"turned_pro already exists or error: {e}")
        
        try:
            conn.execute(text("ALTER TABLE players ADD COLUMN prize_money VARCHAR"))
            print("Added prize_money")
        except Exception as e: print(f"prize_money already exists or error: {e}")
        
        conn.commit()
        print("Migration complete.")

if __name__ == "__main__":
    migrate()
