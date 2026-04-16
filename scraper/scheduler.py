import schedule
import time
import subprocess
from scraper.utils.logger import log

def run_task():
    log.info("Starting scheduled scraper run...")
    try:
        # Running main_scraper.py as a separate process to ensure clean environment
        # Alternatively, call main_scraper.run_scraper() directly
        subprocess.run(["python3", "-m", "scraper.main_scraper"], check=True)
        log.info("Scheduled scraper run finished.")
    except Exception as e:
        log.error(f"Scheduled task failed: {e}")

# Schedule to run every day at midnight
schedule.every().day.at("00:00").do(run_task)

if __name__ == "__main__":
    log.info("Scheduler started. Waiting for tasks...")
    # Initial run on start (optional)
    # run_task()
    
    while True:
        schedule.run_pending()
        time.sleep(60)
