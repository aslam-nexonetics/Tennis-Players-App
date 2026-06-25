import os
import sys
from dotenv import load_dotenv
from sqlalchemy import text

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import engine

def main():
    dialect_name = engine.dialect.name
    print(f"Connecting to database using dialect: {dialect_name}")
    
    with engine.begin() as conn:
        if dialect_name == "postgresql":
            sql = """
            UPDATE tt_players_historical hp
            SET 
              birth_year = CAST(EXTRACT(YEAR FROM ap.birth_date) AS INTEGER),
              birth_month = CAST(EXTRACT(MONTH FROM ap.birth_date) AS INTEGER),
              birth_date = CAST(EXTRACT(DAY FROM ap.birth_date) AS INTEGER),
              picture = COALESCE(hp.picture, ap.image_url)
            FROM table_tennis_players ap
            WHERE 
              hp.birth_year IS NULL
              AND ap.birth_date IS NOT NULL
              AND (
                LOWER(hp.first_name || ' ' || hp.last_name) = LOWER(ap.name)
                OR LOWER(hp.last_name || ' ' || hp.first_name) = LOWER(ap.name)
              );
            """
            result = conn.execute(text(sql))
            print(f"Successfully synchronized {result.rowcount} players on PostgreSQL.")
            
        elif dialect_name == "sqlite":
            sql = """
            UPDATE tt_players_historical
            SET
              birth_year = CAST(strftime('%Y', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              birth_month = CAST(strftime('%m', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              birth_date = CAST(strftime('%d', (
                SELECT birth_date FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              )) AS INTEGER),
              picture = COALESCE(picture, (
                SELECT image_url FROM table_tennis_players 
                WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                   OR LOWER(name) = LOWER(last_name || ' ' || first_name) 
                LIMIT 1
              ))
            WHERE birth_year IS NULL AND EXISTS (
              SELECT 1 FROM table_tennis_players 
              WHERE LOWER(name) = LOWER(first_name || ' ' || last_name) 
                 OR LOWER(name) = LOWER(last_name || ' ' || first_name)
            );
            """
            result = conn.execute(text(sql))
            print(f"Successfully synchronized {result.rowcount} players on SQLite.")
        else:
            print(f"Unsupported database dialect for direct SQL sync: {dialect_name}")

if __name__ == "__main__":
    main()
