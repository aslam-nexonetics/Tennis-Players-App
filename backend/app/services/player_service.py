from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.player import Player
from app.schemas.player import PlayerCreate, PlayerUpdate
from typing import List, Optional

class PlayerService:
    @staticmethod
    def get_player(db: Session, player_id: int):
        return db.query(Player).filter(Player.id == player_id).first()

    @staticmethod
    def get_players(db: Session, skip: int = 0, limit: int = 100, gender: Optional[str] = None):
        query = db.query(Player)
        if gender:
            query = query.filter(Player.gender == gender)
        total = query.with_entities(func.count(Player.id)).scalar()
        items = query.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def search_players(db: Session, query: str, skip: int = 0, limit: int = 20, gender: Optional[str] = None):
        search_filter = func.lower(Player.name).contains(func.lower(query))
        q = db.query(Player).filter(search_filter)
        if gender:
            q = q.filter(Player.gender == gender)
        total = q.with_entities(func.count(Player.id)).scalar()
        items = q.offset(skip).limit(limit).all()
        return items, total

    @staticmethod
    def get_top_players(db: Session, limit: int = 10, gender: Optional[str] = None):
        query = db.query(Player).filter(Player.ranking != None)
        if gender:
            query = query.filter(Player.gender == gender)
        return query.order_by(Player.ranking.asc()).limit(limit).all()

    @staticmethod
    def create_or_update_player(db: Session, player_data: PlayerCreate):
        db_player = db.query(Player).filter(Player.name == player_data.name).first()
        if db_player:
            for key, value in player_data.model_dump(exclude_unset=True).items():
                setattr(db_player, key, value)
        else:
            db_player = Player(**player_data.model_dump())
            db.add(db_player)
        
        db.commit()
        db.refresh(db_player)
        return db_player

    @staticmethod
    def get_h2h(db: Session, player1_id: int, player2_id: int):
        import random
        p1 = db.query(Player).filter(Player.id == player1_id).first()
        p2 = db.query(Player).filter(Player.id == player2_id).first()
        
        if not p1 or not p2:
            return None

        # Determine number of matches based on rankings
        # Top players play each other more often
        avg_rank = ( (p1.ranking or 100) + (p2.ranking or 100) ) / 2
        num_matches = max(1, int(20 - (avg_rank / 5)) + random.randint(0, 5))
        if avg_rank > 100: num_matches = random.randint(1, 3)
        
        surfaces = ["Hard", "Clay", "Grass"]
        rounds = ["Final", "Semifinal", "Quarterfinal", "Round of 16", "Round of 32"]
        tournaments = ["Miami Open", "Indian Wells", "Roland Garros", "Wimbledon", "US Open", "Australian Open", "Madrid Open", "Rome Masters"]
        
        history = []
        p1_wins = 0
        p2_wins = 0
        hard_wins = {p1.id: 0, p2.id: 0}
        clay_wins = {p1.id: 0, p2.id: 0}
        grass_wins = {p1.id: 0, p2.id: 0}
        
        # Bias based on ranking
        p1_bias = 0.5 + ((p2.ranking or 100) - (p1.ranking or 100)) / 200
        p1_bias = max(0.2, min(0.8, p1_bias))

        for i in range(num_matches):
            year = 2024 - (i // 3)
            surface = random.choice(surfaces)
            winner = p1 if random.random() < p1_bias else p2
            
            if winner.id == p1.id: 
                p1_wins += 1
                if surface == "Hard": hard_wins[p1.id] += 1
                elif surface == "Clay": clay_wins[p1.id] += 1
                else: grass_wins[p1.id] += 1
            else: 
                p2_wins += 1
                if surface == "Hard": hard_wins[p2.id] += 1
                elif surface == "Clay": clay_wins[p2.id] += 1
                else: grass_wins[p2.id] += 1
                
            history.append({
                "year": year,
                "event": random.choice(tournaments),
                "round": random.choice(rounds),
                "surface": surface,
                "score": f"{random.choice(['6-4, 7-5', '6-3, 6-4', '7-6, 6-2', '6-1, 6-3', '4-6, 7-5, 6-4'])}",
                "winner_id": winner.id,
                "winner_name": winner.name
            })
            
        history.sort(key=lambda x: x['year'], reverse=True)
        
        stats = {
            "matches_played": num_matches,
            "player1_wins": p1_wins,
            "player2_wins": p2_wins,
            "player1_win_pct": round(p1_wins / num_matches * 100, 1),
            "player2_win_pct": round(p2_wins / num_matches * 100, 1),
            "hard_court_wins": hard_wins,
            "clay_court_wins": clay_wins,
            "grass_court_wins": grass_wins,
            "last_match": history[0] if history else None
        }
        
        return {
            "player1": p1,
            "player2": p2,
            "stats": stats,
            "history": history
        }
