from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel


class AdminClaimOut(BaseModel):
    id: str
    user_id: str
    store_id: str
    order_id: str
    description: str | None = None
    screenshot_url: str | None = None
    status: str
    created_at: datetime | None = None
    resolved_at: datetime | None = None


class AdminClaimsResponse(BaseModel):
    claims: list[AdminClaimOut]
    pagination: dict


class AdminClaimAuditEvent(BaseModel):
    id: str
    admin_id: str
    action: str
    created_at: datetime | None = None


class AdminClaimAuditResponse(BaseModel):
    events: list[AdminClaimAuditEvent]
