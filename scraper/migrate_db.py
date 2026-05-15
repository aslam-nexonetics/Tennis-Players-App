import sys
import os
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import engine
from sqlalchemy import text

def migrate():
    print("Migrating players table...")
    
    columns = [
        ("titles", "INTEGER DEFAULT 0"),
        ("turned_pro", "VARCHAR"),
        ("prize_money", "VARCHAR"),
    ]
    
    for col_name, col_type in columns:
        with engine.begin() as conn:
            try:
                conn.execute(text(f"ALTER TABLE players ADD COLUMN {col_name} {col_type}"))
                print(f"Added {col_name}")
            except Exception as e:
                print(f"{col_name} might already exist: {e}")
    
    print("Migration complete.")

if __name__ == "__main__":
    migrate()
