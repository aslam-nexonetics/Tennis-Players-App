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
from app.schemas.basketball_player import BasketballPlayerCreate

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
                "image_url": "https://img.bleacherreport.net/img/images/photos/003/926/845/8d10b7b1349a888c3a778e36398f62b1_crop_north.jpg?h=900&w=1350&q=70&crop_x=center&crop_y=top",
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
                "image_url": "https://img.bleacherreport.net/img/images/photos/003/926/847/5a0c868953187c3e1e92d24294a61f43_crop_north.jpg?h=900&w=1350&q=70&crop_x=center&crop_y=top",
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
                "image_url": "https://img.bleacherreport.net/img/images/photos/003/926/848/7e97f7422f960f2597405e6085a676b7_crop_north.jpg?h=900&w=1350&q=70&crop_x=center&crop_y=top",
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
                "image_url": "https://img.bleacherreport.net/img/images/photos/003/926/849/f635f79a9f9390234a96b797f3987f22_crop_north.jpg?h=900&w=1350&q=70&crop_x=center&crop_y=top",
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
                "image_url": "https://img.bleacherreport.net/img/images/photos/003/926/850/c215e98f62f3f124483a3026369799c9_crop_north.jpg?h=900&w=1350&q=70&crop_x=center&crop_y=top",
                "source": "NBA Data Simulation"
            }
        ]

        # Add some more generic players
        for i in range(6, 51):
            name = f"Basketball Player {i}"
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
                "image_url": f"https://images.unsplash.com/photo-1546519638-68e109498ffc?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3",
                "source": "Generated Data"
            })

        for p in players_data:
            try:
                player_create = BasketballPlayerCreate(**p)
                BasketballPlayerService.create_or_update_player(self.db, player_create)
                print(f"Saved: {p['name']}")
            except Exception as e:
                print(f"Error saving {p['name']}: {e}")

        self.db.close()
        print("Basketball scraping completed.")

if __name__ == "__main__":
    scraper = BasketballScraper()
    scraper.scrape_basketball_players()
