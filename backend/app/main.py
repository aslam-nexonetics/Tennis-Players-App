from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import players
from app.db.session import engine, Base
import uvicorn

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Tennis Player Search API",
    description="Backend API for searching and viewing tennis player data.",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to the frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(players.router, prefix="/players", tags=["Players"])

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

@app.get("/")
def read_root():
    return {"message": "Welcome to the Tennis Player Search API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
