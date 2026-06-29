import sqlite3

sqlite_path = "/home/nexonetics/nexonetics/tennis_app/tennis.db"
conn = sqlite3.connect(sqlite_path)
cursor = conn.cursor()

# Get all tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()
print("Tables in SQLite database:")
for t in tables:
    table_name = t[0]
    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
    count = cursor.fetchone()[0]
    print(f" - {table_name}: {count} records")
    
    # Check table structure / sample for dates if relevant
    cursor.execute(f"PRAGMA table_info({table_name})")
    cols = [col[1] for col in cursor.fetchall()]
    print(f"   Columns: {cols}")
    
    # Try to find date/ranking date columns and query max
    date_cols = [c for c in cols if 'date' in c.lower() or 'year' in c.lower() or 'updated' in c.lower()]
    if date_cols:
        print(f"   Potential date columns: {date_cols}")
        for dc in date_cols:
            try:
                cursor.execute(f"SELECT MAX({dc}) FROM {table_name}")
                max_val = cursor.fetchone()[0]
                print(f"     Max {dc}: {max_val}")
            except Exception as e:
                print(f"     Error querying max of {dc}: {e}")

conn.close()
