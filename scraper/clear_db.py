import sys
import os
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import engine
from sqlalchemy import text

def clear():
    with engine.connect() as conn:
        print("Clearing players table...")
        conn.execute(text("DELETE FROM players"))
        conn.commit()
        print("Done.")

if __name__ == "__main__":
    clear()
