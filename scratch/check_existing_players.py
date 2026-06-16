import sys
import os

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)
sys.path.append(os.path.join(project_root, 'backend'))

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, 'backend', '.env'))

from app.db.session import SessionLocal
from app.models.player import Player

def main():
    db = SessionLocal()
    try:
        total = db.query(Player).count()
        with_birth = db.query(Player).filter(Player.birth_date.isnot(None)).count()
        with_prize = db.query(Player).filter(Player.prize_money.isnot(None)).count()
        with_img = db.query(Player).filter(Player.image_url.isnot(None)).count()
        
        print(f"Total tennis players in db: {total}")
        print(f"With birth date: {with_birth}")
        print(f"With prize money: {with_prize}")
        print(f"With image URL: {with_img}")
        
        # sample a few
        samples = db.query(Player).limit(5).all()
        for p in samples:
            print(f"Name: {p.name}, Gender: {p.gender}, Country: {p.country}, Birth: {p.birth_date}, Prize: {p.prize_money}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
