from fastapi import APIRouter
from .routes.health import router as health_router
from .routes.auth import router as auth_router
from .routes.stores import router as stores_router
from .routes.activate import router as activate_router
from .routes.webhooks import router as webhooks_router
from .routes.withdrawals import router as withdrawals_router
from .routes.admin_withdrawals import router as admin_withdrawals_router
from .routes.claims import router as claims_router
from .routes.admin_claims import router as admin_claims_router
from .routes.admin import router as admin_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(stores_router)
api_router.include_router(activate_router)
api_router.include_router(webhooks_router)
api_router.include_router(withdrawals_router)
api_router.include_router(admin_withdrawals_router)
api_router.include_router(claims_router)
api_router.include_router(admin_claims_router)
api_router.include_router(admin_router)
