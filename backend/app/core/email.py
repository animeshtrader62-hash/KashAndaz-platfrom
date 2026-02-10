from __future__ import annotations

import smtplib
from email.message import EmailMessage
import structlog

from app.core.config import settings


logger = structlog.get_logger(__name__)


def send_password_reset_email(*, to_email: str, reset_link: str) -> None:
    if not settings.smtp_host or not settings.smtp_username or not settings.smtp_password or not settings.smtp_from_email:
        env = (getattr(settings, "app_env", None) or "development").lower()
        if env not in {"prod", "production"}:
            # Dev-only fallback: allow password reset flow without SMTP.
            # The reset link is logged for local testing.
            logger.warning(
                "smtp_not_configured_dev_password_reset_link",
                to_email=to_email,
                reset_link=reset_link,
            )
            return
        raise RuntimeError("SMTP is not configured")

    msg = EmailMessage()
    msg["Subject"] = "KashAndaz Admin Password Reset"
    msg["From"] = settings.smtp_from_email
    msg["To"] = to_email
    msg.set_content(
        "You requested a password reset for KashAndaz Admin.\n\n"
        f"Reset link (valid for 15 minutes):\n{reset_link}\n\n"
        "If you did not request this, you can ignore this email."
    )

    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
            if settings.smtp_use_starttls:
                smtp.starttls()
            smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(msg)
    except Exception:
        logger.exception(
            "smtp_send_failed",
            to_email=to_email,
            smtp_host=settings.smtp_host,
            smtp_port=settings.smtp_port,
            smtp_use_starttls=bool(settings.smtp_use_starttls),
        )
        raise