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

    if os.getenv("MEMORY_DEBUG") == "1":
        tracemalloc.start()
        logger.info("memory_debug_enabled")

    # Ensure all tables exist (MVP, no migrations yet).
    try:
        Base.metadata.create_all(engine)
    except Exception:
        # In some environments (e.g. tests/CI) the configured DB may not be available.
        # Tests override the DB dependency and create schema separately.
        pass

    scheduler = BackgroundScheduler()

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        scheduler.add_job(run_confirmation_job, "interval", hours=24, id="confirm_job")
        scheduler.add_job(run_risk_job, "interval", hours=24, id="risk_job")
        scheduler.start()
        try:
            yield
        finally:
            scheduler.shutdown(wait=False)

    app = FastAPI(title=settings.app_name, lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        # NOTE: Browsers disallow `Access-Control-Allow-Origin: *` together with
        # `Access-Control-Allow-Credentials: true`. Starlette enforces this.
        # Using a permissive regex achieves the same goal for development.
        allow_origin_regex=r".*",
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
