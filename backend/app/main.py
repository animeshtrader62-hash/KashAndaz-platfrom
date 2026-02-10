from contextlib import asynccontextmanager
import os
import time
import tracemalloc
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.background import BackgroundScheduler
import structlog
from .core.config import settings
from .core.logging import configure_logging
from .core.sentry import configure_sentry
from .api.router import api_router
from .jobs.confirmation_job import run_confirmation_job
from .jobs.risk_job import run_risk_job
from .core.middleware import RequestIdMiddleware

# Import models to register metadata
from . import models  # noqa: F401
from .db.base import Base
from .db.session import engine


def create_app() -> FastAPI:
    configure_logging(settings.app_log_level)
    configure_sentry()
    logger = structlog.get_logger(__name__)

    app_env = (getattr(settings, "app_env", None) or os.getenv("APP_ENV") or "development").lower()

    if os.getenv("MEMORY_DEBUG") == "1":
        tracemalloc.start()
        logger.info("memory_debug_enabled")

    # Dev convenience only. In production, schema is managed by Alembic migrations.
    auto_create_schema = os.getenv("AUTO_CREATE_SCHEMA", "1") == "1"
    if app_env != "production" and auto_create_schema:
        try:
            Base.metadata.create_all(engine)
        except Exception:
            # In some environments (e.g. tests/CI) the configured DB may not be available.
            # Tests override the DB dependency and create schema separately.
            pass

    # IMPORTANT: APScheduler's BackgroundScheduler runs in-process.
    # In production, multi-worker setups (e.g. Uvicorn/Gunicorn workers) would
    # start one scheduler per worker unless explicitly guarded.
    scheduler_enabled = os.getenv("ENABLE_SCHEDULER", "0") == "1"
    scheduler = BackgroundScheduler() if scheduler_enabled else None

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        if scheduler is not None:
            logger.info("scheduler_starting")
            scheduler.add_job(
                run_confirmation_job,
                "interval",
                hours=24,
                id="confirm_job",
                replace_existing=True,
            )
            scheduler.add_job(
                run_risk_job,
                "interval",
                hours=24,
                id="risk_job",
                replace_existing=True,
            )
            scheduler.start()
        try:
            yield
        finally:
            if scheduler is not None:
                scheduler.shutdown(wait=False)

    app = FastAPI(title=settings.app_name, lifespan=lifespan)

    cors_allow_origin_regex = os.getenv("CORS_ALLOW_ORIGIN_REGEX")
    cors_allow_origins_raw = os.getenv("CORS_ALLOW_ORIGINS")
    cors_allow_origins = (
        [o.strip() for o in cors_allow_origins_raw.split(",") if o.strip()]
        if cors_allow_origins_raw
        else None
    )

    # Production safety: do not allow wildcard CORS unless explicitly configured.
    if app_env in {"prod", "production"} and not cors_allow_origin_regex and not cors_allow_origins:
        raise RuntimeError(
            "Production CORS must be explicitly configured via CORS_ALLOW_ORIGINS or CORS_ALLOW_ORIGIN_REGEX"
        )

    app.add_middleware(
        CORSMiddleware,
        # NOTE: Browsers disallow `Access-Control-Allow-Origin: *` together with
        # `Access-Control-Allow-Credentials: true`. Starlette enforces this.
        # Keep permissive behavior for development, but require explicit config in production.
        allow_origins=cors_allow_origins or [],
        allow_origin_regex=cors_allow_origin_regex if cors_allow_origin_regex else (r".*" if app_env not in {"prod", "production"} else None),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(RequestIdMiddleware)
    app.include_router(api_router, prefix="/api")

    @app.middleware("http")
    async def _perf_middleware(request, call_next):
        if os.getenv("MEMORY_DEBUG") != "1":
            return await call_next(request)

        start = time.perf_counter()
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000.0

        current, peak = tracemalloc.get_traced_memory()
        logger.info(
            "request_perf",
            method=request.method,
            path=request.url.path,
            status_code=getattr(response, "status_code", None),
            elapsed_ms=round(elapsed_ms, 2),
            py_alloc_current_kb=int(current / 1024),
            py_alloc_peak_kb=int(peak / 1024),
        )
        return response

    return app


app = create_app()
