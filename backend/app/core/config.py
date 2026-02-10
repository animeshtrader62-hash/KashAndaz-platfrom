from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "KashAndaz API"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_log_level: str = "INFO"

    api_base_url: str = "http://localhost:8000"

    database_url: str = "postgresql+psycopg://user:pass@localhost:5432/kashandaz"
    redis_url: str = "redis://localhost:6379/0"

    sentry_dsn: str | None = None

    jwt_secret: str = "CHANGE_ME"
    jwt_algorithm: str = "HS256"
    access_token_exp_minutes: int = 60
    refresh_token_exp_days: int = 30

    # Admin-panel-only auth restrictions
    admin_email_domain: str = "kashandaz.com"

    # Email (Zoho SMTP) for password reset
    smtp_host: str | None = None
    smtp_port: int = 587
    smtp_username: str | None = None
    smtp_password: str | None = None
    smtp_from_email: str | None = None
    smtp_use_starttls: bool = True

    # Admin panel URL used to build reset links
    admin_panel_base_url: str = "http://localhost:5173"

    # Base URL for first-party redirect endpoint.
    # Production should set this to e.g. https://api.kashandaz.com/api/r
    tracking_redirect_base: str = "http://localhost:8000/api/r"

    webhook_secret: str = "CHANGE_ME_WEBHOOK_SECRET"
    webhook_signature_header: str = "X-Signature"

    fcm_server_key: str | None = None
    ses_sender_email: str | None = None

    payout_provider: str | None = None
    s3_bucket: str | None = None
    s3_region: str | None = None
    s3_access_key: str | None = None
    s3_secret_key: str | None = None

    min_withdrawal_amount: float = 50.0

    def model_post_init(self, __context) -> None:  # type: ignore[override]
        env = (self.app_env or "development").lower()
        if env not in {"prod", "production"}:
            return

        if not self.jwt_secret or self.jwt_secret.startswith("CHANGE_ME"):
            raise ValueError("JWT_SECRET must be set to a non-default value in production")

        if not self.webhook_secret or self.webhook_secret.startswith("CHANGE_ME"):
            raise ValueError("WEBHOOK_SECRET must be set to a non-default value in production")

        if not self.tracking_redirect_base or "localhost" in self.tracking_redirect_base:
            raise ValueError("TRACKING_REDIRECT_BASE must be set for production")

        if not self.admin_panel_base_url or "localhost" in self.admin_panel_base_url:
            raise ValueError("ADMIN_PANEL_BASE_URL must be set for production")

        # Password reset email must be deliverable in production.
        if not self.smtp_host or not self.smtp_username or not self.smtp_password or not self.smtp_from_email:
            raise ValueError(
                "SMTP settings (SMTP_HOST/SMTP_USERNAME/SMTP_PASSWORD/SMTP_FROM_EMAIL) must be set for production"
            )

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
