import sys
import os

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import engine
from sqlalchemy import text

with engine.connect() as conn:
    print("Dropping table_tennis_players table...")
    conn.execute(text("DROP TABLE IF EXISTS table_tennis_players"))
    conn.commit()
    print("Table dropped successfully.")
