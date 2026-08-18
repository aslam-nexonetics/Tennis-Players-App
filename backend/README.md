# Backend Setup & Execution Guide

Step-by-step guide to running the FastAPI backend locally for development and testing.

---

## 📋 Prerequisites

- **Python 3.9+** (Python 3.10, 3.11, or 3.12 recommended)
- **pip** (Python package installer)
- **SQLite** (bundled with Python by default) or **PostgreSQL** (optional)

---

## 🚀 Step-by-Step Instructions

### Step 1: Navigate to the Backend Directory
From the root of the project repository, change directory into `backend`:
```bash
cd backend
```

### Step 2: Set Up a Virtual Environment (Recommended)
Create and activate a isolated Python virtual environment to manage dependencies.

- **Linux / macOS:**
  ```bash
  python3 -m venv venv
  source venv/bin/activate
  ```

- **Windows (PowerShell / Command Prompt):**
  ```powershell
  python -m venv venv
  venv\Scripts\activate
  ```

### Step 3: Install Required Dependencies
Install the required packages using `requirements.txt`:
```bash
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables
Ensure a `.env` file exists in the `backend/` folder with your database connection configuration.

- **Default (SQLite Local Database):**
  ```env
  DATABASE_URL=sqlite:///./tennis.db
  ```

- **Optional (External PostgreSQL Database):**
  ```env
  DATABASE_URL=postgresql://<user>:<password>@<host>:<port>/<dbname>?sslmode=require
  ```

### Step 5: Run the Server
Start the FastAPI server using `uvicorn` with hot-reloading enabled for development:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Alternatively, run via python module:
```bash
python -m uvicorn app.main:app --reload --port 8000
```

---

## 🌐 Verifying Execution

Once the server starts up, you can check the API endpoints in your browser:

- **API Base URL:** `http://localhost:8000/`
- **Interactive Swagger Docs:** `http://localhost:8000/docs`
- **Alternative ReDoc Docs:** `http://localhost:8000/redoc`

---

## 🧪 Running Backend Tests

To run the test suite using `pytest`:

```bash
PYTHONPATH=. pytest
```
*(Or `./venv/bin/pytest` if using virtualenv)*

---

## 🛠️ Common Endpoints Summary

- `GET /` - Root health check
- `POST /auth/register` & `POST /auth/token` - Authentication
- `GET /players` - Tennis players listing & search
- `GET /tt-players` - Table Tennis players
- `GET /football-national-teams` - Football National Teams
- `GET /basketball-clubs` - Basketball Clubs
