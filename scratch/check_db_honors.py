
import sqlite3
import json
import os

db_path = 'backend/tennis.db'
if not os.path.exists(db_path):
    db_path = 'tennis.db' # Fallback to root

print(f"Checking database at {db_path}...")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT name, world_cup_titles, honors_json FROM football_national_teams WHERE world_cup_titles > 0 OR (honors_json IS NOT NULL AND honors_json != '{}') LIMIT 20")
rows = cursor.fetchall()

print(f"{'Team':20} | {'WC':2} | {'Honors'}")
print("-" * 60)
for row in rows:
    honors = json.loads(row[2]) if row[2] else {}
    print(f"{row[0]:20} | {row[1]:2} | {honors}")

conn.close()
