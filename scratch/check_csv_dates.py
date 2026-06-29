import os
import csv

for filename in ['players.csv', 'tt_players.csv']:
    path = os.path.join('/home/nexonetics/nexonetics/tennis_app/scratch', filename)
    if os.path.exists(path):
        print(f"--- {filename} ---")
        try:
            with open(path, mode='r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                print(f"Headers: {headers}")
                
                # Check rows and find max date values
                date_indices = [i for i, h in enumerate(headers) if 'date' in h.lower() or 'year' in h.lower()]
                if date_indices:
                    max_vals = {headers[idx]: None for idx in date_indices}
                    row_count = 0
                    for row in reader:
                        row_count += 1
                        for idx in date_indices:
                            col_name = headers[idx]
                            if idx < len(row) and row[idx].strip():
                                val = row[idx].strip()
                                if max_vals[col_name] is None or val > max_vals[col_name]:
                                    max_vals[col_name] = val
                    print(f"Rows: {row_count}")
                    for col_name, max_val in max_vals.items():
                        print(f"  Max {col_name}: {max_val}")
                else:
                    print("No date/year columns found.")
        except Exception as e:
            print(f"Error reading {filename}: {e}")
