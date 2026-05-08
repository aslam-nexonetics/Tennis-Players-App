import sys
import os
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from app.db.session import engine
from sqlalchemy import text

def reset_tt():
    with engine.connect() as conn:
        print("Clearing table_tennis_players table...")
        conn.execute(text("DELETE FROM table_tennis_players"))
        conn.commit()
        print("Table cleared.")
        
    print("Triggering TT Scraper...")
    import subprocess
    scraper_path = os.path.join(project_root, "scraper", "main_scraper.py")
    python_path = os.path.join(project_root, "scraper", "venv", "bin", "python3")
    
    # Run scraper
    subprocess.run([python_path, scraper_path, "--tt-only"], check=True)
    print("Reset and Scrape complete.")

if __name__ == "__main__":
    reset_tt()
