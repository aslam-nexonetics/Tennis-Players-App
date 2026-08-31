import sqlite3
import json

db_path = "/home/nexonetics/nexonetics/tennis_app/tennis.db"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

print("==========================================")
print("📊 VERIFYING TENNIS RANKING DATA (2026-08-31)")
print("==========================================")

# Check Tennis Latest Date
cursor.execute("""
    SELECT ranking_year, ranking_month, ranking_date 
    FROM tennis_rankings_historical 
    ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC 
    LIMIT 1
""")
r_tennis = cursor.fetchone()
ty, tm, td = r_tennis['ranking_year'], r_tennis['ranking_month'], r_tennis['ranking_date']
print(f"Latest Tennis Ranking Date: {ty}-{tm:02d}-{td:02d}")

# Check ATP (Male - gender = 0) Ranks
cursor.execute("""
    SELECT h.first_name, h.last_name, h.country, r.rank, r.points
    FROM tennis_rankings_historical r
    JOIN tennis_players_historical h ON r.player_id = h.id
    WHERE r.ranking_year = ? AND r.ranking_month = ? AND r.ranking_date = ? AND h.gender = 0
    ORDER BY r.rank ASC
""", (ty, tm, td))
atp_players = [dict(row) for row in cursor.fetchall()]
print(f"\n🎾 ATP (Men's) total ranked players on {ty}-{tm:02d}-{td:02d}: {len(atp_players)}")

# Check ATP duplicates
atp_ranks = [p['rank'] for p in atp_players]
atp_dup_ranks = [r for r in set(atp_ranks) if atp_ranks.count(r) > 1]
if atp_dup_ranks:
    print(f"⚠️ Warning: Found duplicate ATP ranks: {atp_dup_ranks}")
else:
    print("✅ Zero duplicate ranks in ATP Men's rankings!")

# Check ATP missing ranks 1..100
expected_atp_ranks = set(range(1, max(atp_ranks) + 1 if atp_ranks else 1))
missing_atp = expected_atp_ranks - set(atp_ranks)
if missing_atp:
    print(f"⚠️ Warning: Missing ATP ranks: {sorted(list(missing_atp))}")
else:
    print("✅ Zero missing ranks in ATP Men's rankings! Continuous sequence 1..N.")

print("\n🏆 Top 10 ATP Men's Singles (Latest):")
for p in atp_players[:10]:
    print(f"  Rank #{p['rank']:<3}: {p['first_name']} {p['last_name']} ({p['country']}) - {p['points']} pts")

# Check WTA (Female - gender = 1) Ranks
cursor.execute("""
    SELECT h.first_name, h.last_name, h.country, r.rank, r.points
    FROM tennis_rankings_historical r
    JOIN tennis_players_historical h ON r.player_id = h.id
    WHERE r.ranking_year = ? AND r.ranking_month = ? AND r.ranking_date = ? AND h.gender = 1
    ORDER BY r.rank ASC
""", (ty, tm, td))
wta_players = [dict(row) for row in cursor.fetchall()]
print(f"\n🎾 WTA (Women's) total ranked players on {ty}-{tm:02d}-{td:02d}: {len(wta_players)}")

wta_ranks = [p['rank'] for p in wta_players]
wta_dup_ranks = [r for r in set(wta_ranks) if wta_ranks.count(r) > 1]
if wta_dup_ranks:
    print(f"⚠️ Warning: Found duplicate WTA ranks: {wta_dup_ranks}")
else:
    print("✅ Zero duplicate ranks in WTA Women's rankings!")

expected_wta_ranks = set(range(1, max(wta_ranks) + 1 if wta_ranks else 1))
missing_wta = expected_wta_ranks - set(wta_ranks)
if missing_wta:
    print(f"⚠️ Warning: Missing WTA ranks: {sorted(list(missing_wta))}")
else:
    print("✅ Zero missing ranks in WTA Women's rankings! Continuous sequence 1..N.")

print("\n🏆 Top 10 WTA Women's Singles (Latest):")
for p in wta_players[:10]:
    print(f"  Rank #{p['rank']:<3}: {p['first_name']} {p['last_name']} ({p['country']}) - {p['points']} pts")

print("\n==========================================")
print("🏓 VERIFYING TABLE TENNIS RANKING DATA (2026-08-24)")
print("==========================================")

# Check TT Latest Date
cursor.execute("""
    SELECT ranking_year, ranking_month, ranking_date 
    FROM tt_rankings_historical 
    ORDER BY ranking_year DESC, ranking_month DESC, ranking_date DESC 
    LIMIT 1
""")
r_tt = cursor.fetchone()
tty, ttm, ttd = r_tt['ranking_year'], r_tt['ranking_month'], r_tt['ranking_date']
print(f"Latest Table Tennis Ranking Date: {tty}-{ttm:02d}-{ttd:02d}")

# Check WTT Men (gender = 0)
cursor.execute("""
    SELECT h.first_name, h.last_name, h.country, r.rank, r.points
    FROM tt_rankings_historical r
    JOIN tt_players_historical h ON r.player_id = h.id
    WHERE r.ranking_year = ? AND r.ranking_month = ? AND r.ranking_date = ? AND h.gender = 0
    ORDER BY r.rank ASC
""", (tty, ttm, ttd))
tt_men = [dict(row) for row in cursor.fetchall()]
print(f"\n🏓 WTT Men's total ranked players on {tty}-{ttm:02d}-{ttd:02d}: {len(tt_men)}")

tt_men_ranks = [p['rank'] for p in tt_men]
tt_men_dups = [r for r in set(tt_men_ranks) if tt_men_ranks.count(r) > 1]
if tt_men_dups:
    print(f"⚠️ Warning: Found duplicate WTT Men's ranks: {tt_men_dups}")
else:
    print("✅ Zero duplicate ranks in WTT Men's rankings!")

print("\n🏆 Top 10 WTT Men's Singles (Latest):")
for p in tt_men[:10]:
    print(f"  Rank #{p['rank']:<3}: {p['first_name']} {p['last_name']} ({p['country']}) - {p['points']} pts")

# Check WTT Women (gender = 1)
cursor.execute("""
    SELECT h.first_name, h.last_name, h.country, r.rank, r.points
    FROM tt_rankings_historical r
    JOIN tt_players_historical h ON r.player_id = h.id
    WHERE r.ranking_year = ? AND r.ranking_month = ? AND r.ranking_date = ? AND h.gender = 1
    ORDER BY r.rank ASC
""", (tty, ttm, ttd))
tt_women = [dict(row) for row in cursor.fetchall()]
print(f"\n🏓 WTT Women's total ranked players on {tty}-{ttm:02d}-{ttd:02d}: {len(tt_women)}")

tt_women_ranks = [p['rank'] for p in tt_women]
tt_women_dups = [r for r in set(tt_women_ranks) if tt_women_ranks.count(r) > 1]
if tt_women_dups:
    print(f"⚠️ Warning: Found duplicate WTT Women's ranks: {tt_women_dups}")
else:
    print("✅ Zero duplicate ranks in WTT Women's rankings!")

print("\n🏆 Top 10 WTT Women's Singles (Latest):")
for p in tt_women[:10]:
    print(f"  Rank #{p['rank']:<3}: {p['first_name']} {p['last_name']} ({p['country']}) - {p['points']} pts")

conn.close()
print("\n==========================================")
print("✅ ALL VERIFICATIONS COMPLETED SUCCESSFULLY!")
print("==========================================")
