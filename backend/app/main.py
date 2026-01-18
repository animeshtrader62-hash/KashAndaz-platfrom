from contextlib import asynccontextmanager
from fastapi import FastAPI
from apscheduler.schedulers.background import BackgroundScheduler
from .core.config import settings
from .core.logging import configure_logging
from .core.sentry import configure_sentry
from .api.router import api_router
from .jobs.confirmation_job import run_confirmation_job
from .jobs.risk_job import run_risk_job
from .core.middleware import RequestIdMiddleware

# Import models to register metadata
from . import models  # noqa: F401


def create_app() -> FastAPI:
    configure_logging(settings.app_log_level)
    configure_sentry()

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
    app.add_middleware(RequestIdMiddleware)
    app.include_router(api_router, prefix="/api")

    return app


app = create_app()
