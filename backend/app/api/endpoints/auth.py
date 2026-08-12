from datetime import datetime, timezone, timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api import deps
from app.core import security
from app.core.config import settings
from app.models.user import User, RefreshToken, PasswordResetToken
from app.schemas.user import (
    UserCreate,
    UserResponse,
    UserUpdate,
    PasswordChangeRequest,
)
from app.schemas.auth import (
    LoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    TokenRefreshResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    MessageResponse,
)
from app.services.email_service import email_service

router = APIRouter()

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    user_in: UserCreate,
    request: Request,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Register a new user account."""
    # Check if email is already taken
    existing_user_email = db.query(User).filter(User.email == user_in.email).first()
    if existing_user_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists."
        )

    # Check if username is already taken
    existing_user_name = db.query(User).filter(User.username == user_in.username).first()
    if existing_user_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This username is already taken. Please choose another one."
        )

    # Create new user
    db_user = User(
        email=user_in.email,
        username=user_in.username,
        full_name=user_in.full_name,
        hashed_password=security.get_password_hash(user_in.password),
        is_active=True,
        is_verified=False,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Generate tokens
    access_token = security.create_access_token(subject=db_user.id)
    raw_refresh_token, refresh_expires_at = security.create_refresh_token(subject=db_user.id)

    # Save refresh token hash in DB
    db_refresh = RefreshToken(
        user_id=db_user.id,
        token_hash=security.hash_token(raw_refresh_token),
        expires_at=refresh_expires_at,
        user_agent=request.headers.get("user-agent"),
        ip_address=request.client.host if request.client else None
    )
    db.add(db_refresh)
    db.commit()

    # Send welcome email asynchronously / log message
    email_service.send_welcome_email(email_to=db_user.email, username=db_user.username)

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(db_user)
    )


@router.post("/login", response_model=TokenResponse)
def login(
    login_data: LoginRequest,
    request: Request,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Authenticate user with email or username and password."""
    identifier = login_data.username_or_email
    
    # Query user by email or username
    user = db.query(User).filter(
        (User.email == identifier) | (User.username == identifier)
    ).first()

    if not user or not security.verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive."
        )

    # Issue tokens
    access_token = security.create_access_token(subject=user.id)
    raw_refresh_token, refresh_expires_at = security.create_refresh_token(subject=user.id)

    # Save refresh token hash in DB
    db_refresh = RefreshToken(
        user_id=user.id,
        token_hash=security.hash_token(raw_refresh_token),
        expires_at=refresh_expires_at,
        user_agent=request.headers.get("user-agent"),
        ip_address=request.client.host if request.client else None
    )
    db.add(db_refresh)
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(user)
    )


@router.post("/token", response_model=TokenResponse)
def login_form(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(deps.get_db)
) -> Any:
    """OAuth2 compatible token login endpoint for Swagger UI."""
    return login(
        login_data=LoginRequest(username_or_email=form_data.username, password=form_data.password),
        request=request,
        db=db
    )


@router.post("/refresh", response_model=TokenRefreshResponse)
def refresh_token(
    refresh_in: RefreshTokenRequest,
    request: Request,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Exchange a valid refresh token for a new access token and rotated refresh token."""
    payload = security.decode_jwt(refresh_in.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token."
        )

    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token payload.")

    try:
        user_id = int(user_id_str)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user ID in refresh token.")

    token_hash = security.hash_token(refresh_in.refresh_token)
    db_refresh = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()

    if not db_refresh or db_refresh.revoked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has been revoked or is invalid."
        )

    now = datetime.now(timezone.utc)
    if db_refresh.expires_at.tzinfo is None:
        db_refresh_expires = db_refresh.expires_at.replace(tzinfo=timezone.utc)
    else:
        db_refresh_expires = db_refresh.expires_at

    if db_refresh_expires < now:
        db_refresh.revoked = True
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired."
        )

    # Revoke old refresh token (Token rotation)
    db_refresh.revoked = True

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with refresh token is invalid or inactive."
        )

    # Issue new access token & new refresh token
    new_access_token = security.create_access_token(subject=user.id)
    new_raw_refresh_token, new_refresh_expires = security.create_refresh_token(subject=user.id)

    new_db_refresh = RefreshToken(
        user_id=user.id,
        token_hash=security.hash_token(new_raw_refresh_token),
        expires_at=new_refresh_expires,
        user_agent=request.headers.get("user-agent"),
        ip_address=request.client.host if request.client else None
    )
    db.add(new_db_refresh)
    db.commit()

    return TokenRefreshResponse(
        access_token=new_access_token,
        refresh_token=new_raw_refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    refresh_in: RefreshTokenRequest,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Revoke refresh token on logout."""
    token_hash = security.hash_token(refresh_in.refresh_token)
    db_refresh = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if db_refresh:
        db_refresh.revoked = True
        db.commit()

    return MessageResponse(message="Successfully logged out.")


@router.get("/me", response_model=UserResponse)
def read_current_user(
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get profile of current authenticated user."""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse)
def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Update profile information of current authenticated user."""
    if user_update.email and user_update.email != current_user.email:
        existing = db.query(User).filter(User.email == user_update.email).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email address is already in use by another account."
            )
        current_user.email = user_update.email

    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return UserResponse.model_validate(current_user)


@router.post("/me/password", response_model=MessageResponse)
def change_password(
    password_change: PasswordChangeRequest,
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Change user password while logged in."""
    if not security.verify_password(password_change.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect."
        )

    current_user.hashed_password = security.get_password_hash(password_change.new_password)
    
    # Revoke all active refresh tokens for security
    db.query(RefreshToken).filter(
        RefreshToken.user_id == current_user.id,
        RefreshToken.revoked == False
    ).update({"revoked": True})

    db.add(current_user)
    db.commit()

    return MessageResponse(message="Password updated successfully.")


@router.post("/forgot-password", response_model=MessageResponse)
def forgot_password(
    request_in: ForgotPasswordRequest,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Request a password reset email."""
    user = db.query(User).filter(User.email == request_in.email).first()
    
    # Secure pattern: Return success message even if email doesn't exist to prevent email enumeration
    if user and user.is_active:
        raw_reset_token = security.generate_random_token()
        token_hash = security.hash_token(raw_reset_token)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES)

        db_reset = PasswordResetToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=expires_at,
            used=False
        )
        db.add(db_reset)
        db.commit()

        email_service.send_password_reset_email(
            email_to=user.email,
            token=raw_reset_token,
            username=user.username
        )

    return MessageResponse(
        message="If an account with that email exists, a password reset instruction has been sent."
    )


@router.post("/reset-password", response_model=MessageResponse)
def reset_password(
    reset_in: ResetPasswordRequest,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Reset user password using token from reset email."""
    token_hash = security.hash_token(reset_in.token)
    db_reset = db.query(PasswordResetToken).filter(
        PasswordResetToken.token_hash == token_hash
    ).first()

    if not db_reset or db_reset.used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset token."
        )

    now = datetime.now(timezone.utc)
    if db_reset.expires_at.tzinfo is None:
        reset_expires = db_reset.expires_at.replace(tzinfo=timezone.utc)
    else:
        reset_expires = db_reset.expires_at

    if reset_expires < now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password reset token has expired."
        )

    user = db.query(User).filter(User.id == db_reset.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user for password reset."
        )

    # Update password and mark token used
    user.hashed_password = security.get_password_hash(reset_in.new_password)
    db_reset.used = True

    # Revoke all active refresh tokens for security
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user.id,
        RefreshToken.revoked == False
    ).update({"revoked": True})

    db.add(user)
    db.add(db_reset)
    db.commit()

    return MessageResponse(message="Password has been reset successfully.")
