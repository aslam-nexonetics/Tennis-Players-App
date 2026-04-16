import time
import random
from scraper.utils.logger import log

def rate_limit(min_delay=1.0, max_delay=3.0):
    """Decorator or helper to add delay between requests."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            delay = random.uniform(min_delay, max_delay)
            log.debug(f"Rate limiting: sleeping for {delay:.2f}s")
            time.sleep(delay)
            return func(*args, **kwargs)
        return wrapper
    return decorator

class RateLimiter:
    def __init__(self, min_delay=1.0, max_delay=3.0):
        self.min_delay = min_delay
        self.max_delay = max_delay

    def wait(self):
        delay = random.uniform(self.min_delay, self.max_delay)
        log.debug(f"Rate limiting: sleeping for {delay:.2f}s")
        time.sleep(delay)
