from pydantic import BaseModel


class AdminWalletSummary(BaseModel):
    total_earned: float
    pending: float
    available: float
    withdrawn: float


class AdminUserOut(BaseModel):
    user_id: str
    email: str
    status: str
    wallet_summary: AdminWalletSummary


class AdminUsersResponse(BaseModel):
    users: list[AdminUserOut]
    pagination: dict
