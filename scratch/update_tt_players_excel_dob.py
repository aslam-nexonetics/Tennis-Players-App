import os
import sys
import re
from datetime import datetime, date
import openpyxl

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.tt_player import TableTennisHistoricalPlayer

CURRENT_YEAR = 2026

def parse_dob_and_age(birth_val, age_val):
    """
    Returns (year, month, day, category) or (None, None, None, category)
    categories: 'full_dob', 'year_only', 'age_calculated', 'none'
    """
    # 1. Check birth date value
    if birth_val is not None:
        if isinstance(birth_val, (datetime, date)):
            return birth_val.year, birth_val.month, birth_val.day, 'full_dob'
        
        b_str = str(birth_val).strip()
        if b_str and b_str.upper() not in ('NA', 'N/A', 'NONE', 'NULL'):
            # Check 4-digit year string
            if re.match(r'^\d{4}$', b_str):
                return int(b_str), 1, 1, 'year_only'
                
            # Clean string
            cleaned = b_str.rstrip('.').strip()
            date_formats = [
                '%B %d, %Y', '%b %d, %Y',
                '%d %B %Y', '%d %b %Y',
                '%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y',
                '%Y/%m/%d', '%d-%m-%Y'
            ]
            for fmt in date_formats:
                try:
                    dt = datetime.strptime(cleaned, fmt)
                    return dt.year, dt.month, dt.day, 'full_dob'
                except ValueError:
                    pass
                    
            # Fallback regex for Year in parentheses or string e.g. "(2005) Name"
            year_match = re.search(r'\b(19\d{2}|20\d{2})\b', cleaned)
            if year_match:
                return int(year_match.group(1)), 1, 1, 'year_only'

    # 2. Check age if birth date was not present / valid
    if age_val is not None:
        a_str = str(age_val).strip()
        if a_str and a_str.upper() not in ('NA', 'N/A', 'NONE', 'NULL'):
            try:
                age_num = int(float(a_str))
                calc_year = CURRENT_YEAR - age_num
                return calc_year, 1, 1, 'age_calculated'
            except ValueError:
                pass

    return None, None, None, 'none'


def main():
    excel_path = os.path.join(project_root, 'scratch', 'finded ages excel.xlsx')
    if not os.path.exists(excel_path):
        print(f"Error: Excel file not found at {excel_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Loading Excel file: {excel_path}")
    wb = openpyxl.load_workbook(excel_path, read_only=True)
    sheet = wb.active

    db = SessionLocal()
    try:
        print("Fetching all TableTennisHistoricalPlayer rows from DB...")
        all_players = {p.id: p for p in db.query(TableTennisHistoricalPlayer).all()}
        print(f"Loaded {len(all_players)} players from database.")

        stats = {
            'total_rows': 0,
            'full_dob': 0,
            'year_only': 0,
            'age_calculated': 0,
            'skipped_no_data': 0,
            'skipped_not_in_db': 0,
            'db_updates': 0
        }

        sample_updates = []

        print("\nProcessing Excel rows and preparing bulk update mappings...")
        update_mappings = []
        for row in sheet.iter_rows(min_row=2, values_only=True):
            if not any(row):
                continue
                
            p_id, name, age, birth_date, status, *rest = row
            if p_id is None:
                continue

            try:
                p_id = int(p_id)
            except ValueError:
                continue

            stats['total_rows'] += 1

            player = all_players.get(p_id)
            if not player:
                stats['skipped_not_in_db'] += 1
                continue

            by, bm, bd, cat = parse_dob_and_age(birth_date, age)
            
            if cat == 'none':
                stats['skipped_no_data'] += 1
                continue

            # Check if DOB actually changes
            if player.birth_year != by or player.birth_month != bm or player.birth_date != bd:
                old_dob = f"{player.birth_year or 'YYYY'}-{player.birth_month or 'MM'}-{player.birth_date or 'DD'}"
                new_dob = f"{by:04d}-{bm:02d}-{bd:02d}"
                
                update_mappings.append({
                    'id': p_id,
                    'birth_year': by,
                    'birth_month': bm,
                    'birth_date': bd
                })
                
                stats['db_updates'] += 1
                stats[cat] += 1

                if len(sample_updates) < 15:
                    sample_updates.append((p_id, f"{player.first_name} {player.last_name}", old_dob, new_dob, cat))

        if update_mappings:
            print(f"\nExecuting ultra-fast raw SQL bulk update for {len(update_mappings)} records...")
            from sqlalchemy import text
            from app.db.session import engine
            
            # Format values for SQL UPDATE FROM VALUES
            # (id, birth_year, birth_month, birth_date)
            vals_str = ", ".join(
                f"({m['id']}, {m['birth_year']}, {m['birth_month']}, {m['birth_date']})"
                for m in update_mappings
            )
            
            sql = f"""
            UPDATE tt_players_historical AS p
            SET
              birth_year = v.by,
              birth_month = v.bm,
              birth_date = v.bd
            FROM (VALUES {vals_str}) AS v(id, by, bm, bd)
            WHERE p.id = v.id;
            """
            
            with engine.begin() as conn:
                res = conn.execute(text(sql))
                print(f"Successfully updated {res.rowcount} rows in PostgreSQL in a single query!")
        else:
            print("No updates needed.")

        print("\n================ SUMMARY ================")
        print(f"Total Excel Rows Processed: {stats['total_rows']}")
        print(f"Database Records Updated:   {stats['db_updates']}")
        print(f"  - Full DOB updated:      {stats['full_dob']}")
        print(f"  - Year Only updated:      {stats['year_only']}")
        print(f"  - Age Calculated updated: {stats['age_calculated']}")
        print(f"Skipped (No DOB/Age Data):  {stats['skipped_no_data']}")
        print(f"Skipped (Not in DB):        {stats['skipped_not_in_db']}")
        print("=========================================")

        print("\nSample Updates:")
        for pid, pname, old_d, new_d, c in sample_updates:
            print(f"  ID {pid:5d} | {pname:30s} | Old: {old_d:10s} -> New: {new_d:10s} ({c})")

    except Exception as e:
        db.rollback()
        print(f"\nError updating database: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
