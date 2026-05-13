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
        
    async with httpx.AsyncClient(verify=False, timeout=20.0) as client:
        try:
            # Clean the URL - sometimes hidden characters can cause issues
            url = url.strip()
            
            # Standard browser headers
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
            }
            
            # Wikipedia specifically likes this User-Agent format
            if "wikimedia.org" in url or "wikipedia.org" in url:
                headers["User-Agent"] = "TennisApp/1.0 (https://github.com/aslam-nexonetics/Tennis-Players-App; contact@example.com)"

            try:
                response = await client.get(url, headers=headers, follow_redirects=True)
            except Exception as first_error:
                # Fallback: Try one more time with NO headers if the first one failed
                try:
                    response = await client.get(url, follow_redirects=True)
                except Exception as second_error:
                    raise Exception(f"Primary error: {str(first_error)}. Fallback error: {str(second_error)}")
            
            if response.status_code != 200:
                print(f"Failed to fetch image from {url}: {response.status_code}")
                raise HTTPException(status_code=response.status_code, detail=f"Source server returned {response.status_code}")
                
            content_type = response.headers.get("Content-Type", "image/jpeg")
            return Response(content=response.content, media_type=content_type)
            
        except Exception as e:
            error_msg = f"Proxy error for {url}: {str(e)}"
            print(error_msg)
            # Return the error message in the detail so we can see it in the network tab
            raise HTTPException(status_code=500, detail=error_msg)


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
