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

    tracking_redirect_base: str = "https://tracking.example.com/redirect"

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

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
