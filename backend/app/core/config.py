from pydantic import AliasChoices, Field, ValidationError, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "KashAndaz API"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_log_level: str = "INFO"

    api_base_url: str = "http://localhost:8000"

    database_url: str = Field(
        ...,
        validation_alias=AliasChoices("DATABASE_URL", "database_url"),
    )
    redis_url: str = Field(
        ...,
        validation_alias=AliasChoices("REDIS_URL", "redis_url"),
    )

    sentry_dsn: str | None = None

    jwt_secret: str = Field(
        ...,
        validation_alias=AliasChoices("JWT_SECRET", "jwt_secret"),
    )
    jwt_algorithm: str = "HS256"
    access_token_exp_minutes: int = 60
    refresh_token_exp_days: int = 30

    # Base URL for first-party redirect endpoint.
    # Production should set this to e.g. https://api.kashandaz.com/api/r
    tracking_redirect_base: str = "http://localhost:8000/api/r"

    webhook_secret: str = Field(
        ...,
        validation_alias=AliasChoices("WEBHOOK_SECRET", "webhook_secret"),
    )
    webhook_signature_header: str = "X-Signature"

    fcm_server_key: str | None = None
    ses_sender_email: str | None = None

    payout_provider: str | None = None
    s3_bucket: str | None = None
    s3_region: str | None = None
    s3_access_key: str | None = None
    s3_secret_key: str | None = None

    min_withdrawal_amount: float = 50.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    @model_validator(mode="after")
    def _disallow_localhost_in_production(self) -> "Settings":
        if (self.app_env or "").strip().lower() != "production":
            return self

        for field_name, url in (
            ("database_url", self.database_url),
            ("redis_url", self.redis_url),
        ):
            url_str = (url or "").lower()
            if "localhost" in url_str or "127.0.0.1" in url_str:
                raise ValueError(f"{field_name} must not point to localhost in production")

        return self


_REQUIRED_ENV_BY_FIELD: dict[str, str] = {
    "database_url": "DATABASE_URL",
    "redis_url": "REDIS_URL",
    "jwt_secret": "JWT_SECRET",
    "webhook_secret": "WEBHOOK_SECRET",
}


def _load_settings_or_die() -> Settings:
    try:
        return Settings()
    except ValidationError as exc:
        missing_fields: list[str] = []
        for err in exc.errors():
            if err.get("type") == "missing":
                loc = err.get("loc")
                if loc and isinstance(loc, (tuple, list)):
                    missing_fields.append(str(loc[0]))

        if missing_fields:
            missing_env = [
                _REQUIRED_ENV_BY_FIELD.get(field, field).upper() for field in missing_fields
            ]
            missing_env_sorted = ", ".join(sorted(set(missing_env)))
            raise RuntimeError(
                f"Missing required environment variables: {missing_env_sorted}"
            ) from None

        raise RuntimeError("Invalid environment configuration") from None


settings = _load_settings_or_die()
