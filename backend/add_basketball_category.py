from app.db.session import engine
from sqlalchemy import text

def add_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE basketball_clubs ADD COLUMN category VARCHAR DEFAULT 'men'"))
            conn.commit()
            print("Successfully added category column to basketball_clubs table.")
        except Exception as e:
            print(f"Error adding column: {e}")

if __name__ == "__main__":
    add_column()
