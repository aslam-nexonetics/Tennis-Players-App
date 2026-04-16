# Tennis Player Search App - Setup Instructions

This is a full-stack application built with FastAPI, PostgreSQL, and Flutter.

## Project Structure
- `backend/`: FastAPI API with SQLAlchemy and Pydantic.
- `scraper/`: Python scraper for ATP, WTA, and Wikipedia data.
- `frontend/`: Flutter mobile and web application.

## Prerequisites
- Python 3.9+
- PostgreSQL
- Flutter SDK

## Backend Setup
1. Navigate to `backend/`.
2. Install dependencies: `pip install -r requirements.txt`.
3. Create a `.env` file with your `DATABASE_URL`.
4. Run the API: `uvicorn app.main:app --reload`.
   - API will be available at `http://localhost:8000`.
   - Interactive docs: `http://localhost:8000/docs`.

## Scraper Setup
1. Navigate to `scraper/`.
2. Install dependencies: `pip install -r requirements.txt`.
3. Run the scraper manually: `python3 main_scraper.py`.
4. To start the daily scheduler: `python3 scheduler.py`.

## Frontend Setup
1. Navigate to `frontend/`.
2. Install dependencies: `flutter pub get`.
3. Run the app: `flutter run`.
   - Supported platforms: Android, iOS, Web, macOS, Windows, Linux.

## Key Features
- **Search**: Case-insensitive name search with 500ms debounce.
- **Data Enrichment**: Scraper uses Wikipedia to fill in missing bio data.
- **Responsive**: Frontend adjusts layout for mobile and web.
- **Top Players**: Quick access to top-ranked players.
