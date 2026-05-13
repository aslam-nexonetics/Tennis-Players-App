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
async def proxy_image(url: str):
    if not url:
        raise HTTPException(status_code=400, detail="URL is required")
        
    async with httpx.AsyncClient(verify=False) as client:
        try:
            # Basic headers to mimic a browser
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
            }
            
            # Special handling for Wikimedia/Wikipedia
            if "wikimedia.org" in url or "wikipedia.org" in url:
                headers["User-Agent"] = "TennisPlayerApp/1.0 (contact@example.com)"
            
            response = await client.get(url, headers=headers, follow_redirects=True, timeout=15.0)
            
            if response.status_code != 200:
                # Log the error internally and return a generic 404 for the image
                print(f"Failed to fetch image from {url}: {response.status_code}")
                raise HTTPException(status_code=response.status_code, detail=f"Failed to fetch image: {response.status_code}")
                
            content_type = response.headers.get("Content-Type", "image/jpeg")
            return Response(content=response.content, media_type=content_type)
        except Exception as e:
            print(f"Proxy error for {url}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Proxy error: {str(e)}")


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
