import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Optional, Union, Tuple
import jwt
import bcrypt

from app.core.config import settings

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify plain password against bcrypt hashed password."""
    try:
        password_bytes = plain_password.encode('utf-8')
        # Truncate password to 72 bytes per bcrypt standard limit
        password_bytes = password_bytes[:72]
        hashed_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(password_bytes, hashed_bytes)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    """Generate bcrypt hash for plain password."""
    password_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode('utf-8')


def hash_token(token: str) -> str:
    """Hash a token string (e.g. refresh or reset token) for secure database storage."""
    return hashlib.sha256(token.encode('utf-8')).hexdigest()

def create_access_token(
    subject: Union[str, Any],
    expires_delta: Optional[timedelta] = None,
    claims: Optional[dict] = None
) -> str:
    """Create a short-lived access JWT token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "iat": now,
        "sub": str(subject),
        "type": "access"
    }
    if claims:
        to_encode.update(claims)
        
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def create_refresh_token(
    subject: Union[str, Any],
    expires_delta: Optional[timedelta] = None
) -> Tuple[str, datetime]:
    """Create a long-lived refresh token. Returns (plain_token, expiry_datetime)."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        
    # Generate a cryptographically random token string combined with JWT for payload verification
    raw_random = secrets.token_urlsafe(32)
    to_encode = {
        "exp": expire,
        "iat": now,
        "sub": str(subject),
        "jti": raw_random,
        "type": "refresh"
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt, expire

def generate_random_token(length: int = 32) -> str:
    """Generate a secure urlsafe random token string."""
    return secrets.token_urlsafe(length)

def decode_jwt(token: str) -> Optional[dict]:
    """Decode and validate JWT token signature and expiration."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None
