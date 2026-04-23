import os
import sys
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
import random

# Add parent directory to path to import app modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backend")))

from app.db.session import SessionLocal
from app.services.basketball_player_service import BasketballPlayerService
from app.schemas.basketball_player import BasketballPlayerCreate, BasketballRankingHistoryCreate

class BasketballScraper:
    def __init__(self):
        self.db = SessionLocal()
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

    def scrape_basketball_players(self):
        """
        Scrapes (or generates for demo) high-quality basketball player data.
        In a real scenario, this would hit NBA.com or Basketball-Reference.
        """
        print("Starting Basketball player data generation...")
        
        # High quality mock data for Basketball
        players_data = [
            {
                "name": "LeBron James",
                "country": "USA",
                "ranking": 1,
                "team": "Los Angeles Lakers",
                "position": "SF/PF",
                "jersey_number": 23,
                "height": "6'9\"",
                "weight": "250 lbs",
                "college": "St. Vincent-St. Mary HS",
                "draft_year": 2003,
                "draft_pick": 1,
                "ppg": 25.7,
                "rpg": 7.3,
                "apg": 8.3,
                "spg": 1.3,
                "bpg": 0.5,
                "fg_pct": 54.0,
                "three_pt_pct": 41.0,
                "ft_pct": 75.0,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/1966.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Stephen Curry",
                "country": "USA",
                "ranking": 2,
                "team": "Golden State Warriors",
                "position": "PG",
                "jersey_number": 30,
                "height": "6'2\"",
                "weight": "185 lbs",
                "college": "Davidson",
                "draft_year": 2009,
                "draft_pick": 7,
                "ppg": 26.4,
                "rpg": 4.5,
                "apg": 5.1,
                "spg": 0.7,
                "bpg": 0.4,
                "fg_pct": 45.0,
                "three_pt_pct": 40.8,
                "ft_pct": 92.3,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3975.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Kevin Durant",
                "country": "USA",
                "ranking": 3,
                "team": "Phoenix Suns",
                "position": "SF",
                "jersey_number": 35,
                "height": "6'11\"",
                "weight": "240 lbs",
                "college": "Texas",
                "draft_year": 2007,
                "draft_pick": 2,
                "ppg": 27.1,
                "rpg": 6.6,
                "apg": 5.0,
                "spg": 0.9,
                "bpg": 1.2,
                "fg_pct": 52.3,
                "three_pt_pct": 41.3,
                "ft_pct": 85.6,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3202.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Giannis Antetokounmpo",
                "country": "Greece",
                "ranking": 4,
                "team": "Milwaukee Bucks",
                "position": "PF",
                "jersey_number": 34,
                "height": "6'11\"",
                "weight": "243 lbs",
                "college": "None",
                "draft_year": 2013,
                "draft_pick": 15,
                "ppg": 30.4,
                "rpg": 11.5,
                "apg": 6.5,
                "spg": 1.2,
                "bpg": 1.1,
                "fg_pct": 61.1,
                "three_pt_pct": 27.4,
                "ft_pct": 65.7,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3032977.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Nikola Jokic",
                "country": "Serbia",
                "ranking": 5,
                "team": "Denver Nuggets",
                "position": "C",
                "jersey_number": 15,
                "height": "6'11\"",
                "weight": "284 lbs",
                "college": "None",
                "draft_year": 2014,
                "draft_pick": 41,
                "ppg": 26.4,
                "rpg": 12.4,
                "apg": 9.0,
                "spg": 1.4,
                "bpg": 0.9,
                "fg_pct": 58.3,
                "three_pt_pct": 35.9,
                "ft_pct": 81.7,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3112335.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Luka Doncic",
                "country": "Slovenia",
                "ranking": 6,
                "team": "Dallas Mavericks",
                "position": "PG/SG",
                "jersey_number": 77,
                "height": "6'7\"",
                "weight": "230 lbs",
                "college": "None",
                "draft_year": 2018,
                "draft_pick": 3,
                "ppg": 33.9,
                "rpg": 9.2,
                "apg": 9.8,
                "spg": 1.4,
                "bpg": 0.5,
                "fg_pct": 48.7,
                "three_pt_pct": 38.2,
                "ft_pct": 78.6,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3945233.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Joel Embiid",
                "country": "Cameroon",
                "ranking": 7,
                "team": "Philadelphia 76ers",
                "position": "C",
                "jersey_number": 21,
                "height": "7'0\"",
                "weight": "280 lbs",
                "college": "Kansas",
                "draft_year": 2014,
                "draft_pick": 3,
                "ppg": 34.7,
                "rpg": 11.0,
                "apg": 5.6,
                "spg": 1.2,
                "bpg": 1.7,
                "fg_pct": 52.9,
                "three_pt_pct": 38.8,
                "ft_pct": 88.3,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/3059318.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Jayson Tatum",
                "country": "USA",
                "ranking": 8,
                "team": "Boston Celtics",
                "position": "SF/PF",
                "jersey_number": 0,
                "height": "6'8\"",
                "weight": "210 lbs",
                "college": "Duke",
                "draft_year": 2017,
                "draft_pick": 3,
                "ppg": 26.9,
                "rpg": 8.1,
                "apg": 4.9,
                "spg": 1.0,
                "bpg": 0.6,
                "fg_pct": 47.1,
                "three_pt_pct": 37.6,
                "ft_pct": 83.3,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/4065648.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Shai Gilgeous-Alexander",
                "country": "Canada",
                "ranking": 9,
                "team": "Oklahoma City Thunder",
                "position": "PG/SG",
                "jersey_number": 2,
                "height": "6'6\"",
                "weight": "195 lbs",
                "college": "Kentucky",
                "draft_year": 2018,
                "draft_pick": 11,
                "ppg": 30.1,
                "rpg": 5.5,
                "apg": 6.2,
                "spg": 2.0,
                "bpg": 0.9,
                "fg_pct": 53.5,
                "three_pt_pct": 35.3,
                "ft_pct": 87.4,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/4277811.png",
                "source": "NBA Data Simulation"
            },
            {
                "name": "Anthony Edwards",
                "country": "USA",
                "ranking": 10,
                "team": "Minnesota Timberwolves",
                "position": "SG",
                "jersey_number": 5,
                "height": "6'4\"",
                "weight": "225 lbs",
                "college": "Georgia",
                "draft_year": 2020,
                "draft_pick": 1,
                "ppg": 25.9,
                "rpg": 5.4,
                "apg": 5.1,
                "spg": 1.3,
                "bpg": 0.5,
                "fg_pct": 46.1,
                "three_pt_pct": 35.7,
                "ft_pct": 83.6,
                "image_url": "https://a.espncdn.com/combiner/i?img=/i/headshots/nba/players/full/4431611.png",
                "source": "NBA Data Simulation"
            }
        ]

        # Add some more generic players with realistic names
        first_names = ["James", "Michael", "Kevin", "Chris", "Derrick", "Kyrie", "Klay", "Damian", "Paul", "Kawhi", "Devin", "Jimmy", "Donovan", "Bam", "De'Aaron", "Tyrese", "Domantas", "Jaylen", "Trae", "Ja"]
        last_names = ["Harden", "Thompson", "Lillard", "George", "Leonard", "Booker", "Butler", "Mitchell", "Adebayo", "Fox", "Haliburton", "Sabonis", "Brown", "Young", "Morant", "Irving", "Rose", "Anthony", "Davis", "Green"]
        
        for i in range(11, 51):
            name = f"{random.choice(first_names)} {random.choice(last_names)}"
            # Ensure no duplicates with the main list if possible, or just accept it for demo
            players_data.append({
                "name": name,
                "country": random.choice(["USA", "Canada", "France", "Spain", "Germany", "Australia"]),
                "ranking": i,
                "team": random.choice(["Boston Celtics", "Miami Heat", "Brooklyn Nets", "Chicago Bulls", "Dallas Mavericks"]),
                "position": random.choice(["PG", "SG", "SF", "PF", "C"]),
                "jersey_number": random.randint(0, 99),
                "height": f"{random.randint(6, 7)}'{random.randint(0, 11)}\"",
                "weight": f"{random.randint(180, 280)} lbs",
                "college": "Various Universities",
                "draft_year": random.randint(2010, 2023),
                "draft_pick": random.randint(1, 60),
                "ppg": round(random.uniform(5.0, 25.0), 1),
                "rpg": round(random.uniform(2.0, 10.0), 1),
                "apg": round(random.uniform(1.0, 8.0), 1),
                "spg": round(random.uniform(0.1, 2.0), 1),
                "bpg": round(random.uniform(0.1, 2.0), 1),
                "fg_pct": round(random.uniform(40.0, 60.0), 1),
                "three_pt_pct": round(random.uniform(25.0, 45.0), 1),
                "ft_pct": round(random.uniform(60.0, 95.0), 1),
                "image_url": "https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=500&auto=format&fit=crop",
                "source": "Generated Data"
            })

        for p in players_data:
            try:
                player_create = BasketballPlayerCreate(**p)
                BasketballPlayerService.create_or_update_player(self.db, player_create)
                print(f"Saved: {p['name']}")
            except Exception as e:
                print(f"Error saving {p['name']}: {e}")

        # Add some ranking history
        print("Generating ranking history...")
        all_players = BasketballPlayerService.get_players(self.db, limit=100)[0]
        for p in all_players:
            # Generate 6 months of history
            current_rank = p.ranking
            for m in range(1, 7):
                # Randomize a bit but stay close to current rank
                hist_rank = max(1, current_rank + random.randint(-5, 10))
                date = datetime(2023, 12 + (m if m <= 0 else m-12), random.randint(1, 28))
                if m > 4: # recent months in 2024
                     date = datetime(2024, m-4, random.randint(1, 28))
                
                hist_create = BasketballRankingHistoryCreate(
                    player_id=p.id,
                    ranking=hist_rank,
                    date=date
                )
                BasketballPlayerService.add_ranking_history(self.db, hist_create)
            print(f"Added history for: {p.name}")

        self.db.close()
        print("Basketball scraping completed.")

if __name__ == "__main__":
    scraper = BasketballScraper()
    scraper.scrape_basketball_players()
