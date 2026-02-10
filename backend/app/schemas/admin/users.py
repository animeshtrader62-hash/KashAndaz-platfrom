from pydantic import BaseModel, EmailStr, Field


class AdminWalletSummary(BaseModel):
    total_earned: float
    pending: float
    available: float
    withdrawn: float


class AdminUserOut(BaseModel):
    user_id: str
    email: str
    role: str | None = None
    name: str | None = None
    status: str
    wallet_summary: AdminWalletSummary


class AdminCreateStaffUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    role: str = Field(pattern=r"^(viewer|admin|super_admin)$")


class AdminSetUserRoleRequest(BaseModel):
    role: str = Field(pattern=r"^(user|viewer|admin|super_admin)$")


class AdminUsersResponse(BaseModel):
    users: list[AdminUserOut]
    pagination: dict
