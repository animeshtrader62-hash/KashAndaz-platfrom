from fastapi import APIRouter
from .routes.health import router as health_router
from .routes.auth import router as auth_router
from .routes.stores import router as stores_router
from .routes.activate import router as activate_router
from .routes.webhooks import router as webhooks_router
from .routes.withdrawals import router as withdrawals_router
from .routes.claims import router as claims_router
from .routes.admin.withdrawals import router as admin_withdrawals_router
from .routes.admin.claims import router as admin_claims_router
from .routes.admin.base import router as admin_router
from .routes.admin.stores import router as admin_stores_router
from .routes.admin.dashboard import router as admin_dashboard_router
from .routes.admin.users import router as admin_users_router
from .routes.admin.orders import router as admin_orders_router
from .routes.admin.offers import router as admin_offers_router
from .routes.admin.banners import router as admin_banners_router
from .routes.admin.auth import router as admin_auth_router
from .routes.home import router as home_router
from .routes.wallet import router as wallet_router
from .routes.transactions import router as transactions_router
from .routes.orders import router as orders_router
from .routes.profile import router as profile_router
from .routes.missing_cashback import router as missing_cashback_router
from .routes.assets import router as assets_router
from .routes.banners import router as banners_router
from .routes.redirect import router as redirect_router

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
api_router.include_router(admin_auth_router)
api_router.include_router(admin_stores_router)
api_router.include_router(admin_dashboard_router)
api_router.include_router(admin_users_router)
api_router.include_router(admin_orders_router)
api_router.include_router(admin_offers_router)
api_router.include_router(admin_banners_router)
api_router.include_router(home_router)
api_router.include_router(wallet_router)
api_router.include_router(transactions_router)
api_router.include_router(orders_router)
api_router.include_router(profile_router)
api_router.include_router(missing_cashback_router)
api_router.include_router(banners_router)
api_router.include_router(redirect_router)
api_router.include_router(assets_router)
