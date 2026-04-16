from loguru import logger
import sys
import os

def setup_logger():
    logger.remove()
    logger.add(sys.stdout, colorize=True, format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>")
    
    log_dir = "logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    logger.add(f"{log_dir}/scraper.log", rotation="1 day", retention="7 days", compression="zip")
    return logger

log = setup_logger()
stone_logger = log # Alias for convenience
