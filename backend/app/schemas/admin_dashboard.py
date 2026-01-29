from pydantic import BaseModel


class AdminDashboardMetrics(BaseModel):
    total_users: int
    total_orders: int
    pending_cashback: float
    confirmed_cashback: float
    paid_cashback: float


class AdminDashboardResponse(BaseModel):
    metrics: AdminDashboardMetrics
