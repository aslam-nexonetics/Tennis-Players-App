import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings

logger = logging.getLogger(__name__)

class EmailService:
    @staticmethod
    def send_password_reset_email(email_to: str, token: str, username: str) -> None:
        """Send password reset email containing reset token or link."""
        subject = "Password Reset Request - Tennis App"
        reset_link = f"/reset-password?token={token}" # Frontend URL pattern
        
        body_text = f"""Hello {username},

You have requested to reset your password for your Tennis App account.

Please use the following token or link to reset your password:
Token: {token}
Reset Link: {reset_link}

This token will expire in {settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES} minutes.

If you did not request a password reset, please ignore this email.

Best regards,
The Tennis App Team
"""
        
        EmailService._send_email(email_to=email_to, subject=subject, body_text=body_text)

    @staticmethod
    def send_welcome_email(email_to: str, username: str) -> None:
        """Send welcome email to newly registered user."""
        subject = "Welcome to Tennis App!"
        body_text = f"""Hello {username},

Welcome to Tennis App! Your account has been successfully created.

Enjoy exploring player stats, historical rankings, and head-to-head records.

Best regards,
The Tennis App Team
"""
        EmailService._send_email(email_to=email_to, subject=subject, body_text=body_text)

    @staticmethod
    def _send_email(email_to: str, subject: str, body_text: str) -> None:
        """Send email via SMTP or log to console if SMTP credentials are missing."""
        if settings.SMTP_HOST and settings.SMTP_USER and settings.SMTP_PASSWORD:
            try:
                msg = MIMEMultipart()
                msg["From"] = f"{settings.EMAILS_FROM_NAME} <{settings.EMAILS_FROM_EMAIL}>"
                msg["To"] = email_to
                msg["Subject"] = subject
                msg.attach(MIMEText(body_text, "plain"))

                with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                    server.starttls()
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                    server.send_message(msg)
                logger.info(f"Email sent successfully to {email_to}")
            except Exception as e:
                logger.error(f"Failed to send email to {email_to}: {str(e)}")
        else:
            # Console output fallback for local development / testing
            logger.info("=== EMAIL NOTIFICATION (DEV / MOCK MODE) ===")
            logger.info(f"To: {email_to}")
            logger.info(f"Subject: {subject}")
            logger.info(f"Body:\n{body_text}")
            logger.info("===========================================")

email_service = EmailService()
