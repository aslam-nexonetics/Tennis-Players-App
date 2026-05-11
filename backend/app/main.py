import httpx
from fastapi import FastAPI, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import players, tt_players, football_national_teams, basketball_clubs
from app.db.session import engine, Base
import uvicorn

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Sports Data API",
    description="Backend API for searching and viewing sports data.",
    version="1.0.0"
)

@app.get("/proxy-image")
def proxy_image(url: str):
    import urllib.request
    import urllib.parse
    try:
        parsed = urllib.parse.urlparse(url)
        base_url = f"{parsed.scheme}://{parsed.netloc}/"
        
        req = urllib.request.Request(
            url, 
            headers={
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
                "Referer": base_url,
            }
        )
        with urllib.request.urlopen(req) as response:
            content = response.read()
            content_type = response.headers.get("Content-Type", "image/jpeg")
            return Response(content=content, media_type=content_type)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


from fastapi.middleware.gzip import GZipMiddleware

# Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to the frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Include routes
app.include_router(players.router, prefix="/players", tags=["Players"])
app.include_router(tt_players.router, prefix="/tt-players", tags=["Table Tennis"])
app.include_router(football_national_teams.router, prefix="/football-national-teams", tags=["Football National Teams"])
app.include_router(basketball_clubs.router, prefix="/basketball-clubs", tags=["Basketball Clubs"])

@app.post("/trigger", tags=["Admin"])
def trigger_scraper():
    import subprocess
    import os
    try:
        # Run scraper as a background process to avoid blocking API
        scraper_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scraper", "main_scraper.py"))
        subprocess.Popen(["python3", scraper_path])
        return {"message": "Scraper triggered in background"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/trigger-tt", tags=["Admin"])
def trigger_tt_scraper():
    import subprocess
    import os
    try:
        scraper_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scraper", "main_scraper.py"))
        subprocess.Popen(["python3", scraper_path, "--tt-only"])
        return {"message": "TT Scraper triggered in background"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/trigger-football-teams", tags=["Admin"])
def trigger_football_team_scraper():
    import subprocess
    import os
    try:
        scraper_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scraper", "main_scraper.py"))
        subprocess.Popen(["python3", scraper_path, "--football-only"])
        return {"message": "Football National Team Scraper triggered in background"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/trigger-basketball-clubs", tags=["Admin"])
def trigger_basketball_scraper():
    import subprocess
    import os
    try:
        scraper_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scraper", "main_scraper.py"))
        subprocess.Popen(["python3", scraper_path, "--basketball-only"])
        return {"message": "Basketball Club Scraper triggered in background"}
    except Exception as e:
        return {"error": str(e)}

@app.get("/")
def read_root():
    return {"message": "Welcome to the Tennis Player Search API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
