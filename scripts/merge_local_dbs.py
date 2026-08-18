import sqlite3
import os
import sys

root_db = "/home/nexonetics/nexonetics/tennis_app/tennis.db"
backend_db = "/home/nexonetics/nexonetics/tennis_app/backend/tennis.db"

if not os.path.exists(root_db) or not os.path.exists(backend_db):
    print(f"One of the databases does not exist: {root_db}, {backend_db}")
    sys.exit(1)

print("Connecting to databases...")
conn_root = sqlite3.connect(root_db)
conn_backend = sqlite3.connect(backend_db)

cur_root = conn_root.cursor()
cur_backend = conn_backend.cursor()

# Tables to migrate from backend_db to root_db
user_tables = [
    "users",
    "refresh_tokens",
    "password_reset_tokens",
    "conversations",
    "conversation_participants",
    "chat_messages"
]

for table in user_tables:
    # Check if table exists in backend_db
    table_exists = cur_backend.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()
    if not table_exists:
        print(f"Table {table} does not exist in backend_db, skipping.")
        continue

    # Get CREATE TABLE statement from backend_db
    create_sql = cur_backend.execute(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()[0]

    # Create table in root_db if it doesn't exist
    cur_root.execute(create_sql)

    # Copy rows
    rows = cur_backend.execute(f"SELECT * FROM {table}").fetchall()
    if rows:
        # Get column names
        cols = [description[0] for description in cur_backend.description]
        placeholders = ", ".join(["?"] * len(cols))
        col_names = ", ".join(cols)

        # Clear existing rows in root_db table if any, then insert
        cur_root.execute(f"DELETE FROM {table}")
        cur_root.executemany(
            f"INSERT OR REPLACE INTO {table} ({col_names}) VALUES ({placeholders})",
            rows
        )
        print(f"Copied {len(rows)} rows for table '{table}' into root tennis.db.")
    else:
        print(f"Table '{table}' has 0 rows.")

conn_root.commit()
conn_root.close()
conn_backend.close()

print("Successfully merged user and chat tables into root tennis.db!")
