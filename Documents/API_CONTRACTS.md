# KashAndaz API Contracts

**Base URL:** `https://api.kashandaz.com` (Replace with actual backend URL)

**Authentication:** Bearer Token in Authorization header

---

## Authentication Endpoints

### POST /api/auth/register
Register a new user

**Request:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string",
  "phone": "string"
}
```

**Response (200):**
```json
{
  "token": "string",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string"
  }
}
```

---

### POST /api/auth/login
Login existing user

**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response (200):**
```json
{
  "token": "string",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string"
  }
}
```

---

## Home / Dashboard Endpoints

### GET /api/home
Get home screen data (wallet summary + top stores)

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "wallet": {
    "total_earned": 1250.50,
    "pending": 450.00,
    "available": 800.50,
    "currency": "INR"
  },
  "top_stores": [
    {
      "id": "string",
      "name": "Amazon",
      "logo_url": "string",
      "cashback_rate": "5%",
      "cashback_type": "percentage",
      "is_active": true
    }
  ]
}
```

---

## Store / Activate Cashback Endpoints

### GET /api/stores
Get all available stores

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `category` (optional): Filter by category
- `search` (optional): Search by name

**Response (200):**
```json
{
  "stores": [
    {
      "id": "string",
      "name": "string",
      "logo_url": "string",
      "cashback_rate": "string",
      "cashback_type": "percentage|flat",
      "category": "string",
      "is_active": boolean
    }
  ]
}
```

---

### POST /api/activate-cashback
Activate cashback for a store (get deep link)

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "store_id": "string",
  "product_url": "string (optional)"
}
```

**Response (200):**
```json
{
  "deep_link": "string",
  "click_id": "string",
  "store_name": "string",
  "message": "Cashback activated! Shop now to earn.",
  "expires_at": "2025-12-17T12:00:00Z"
}
```

**Error (400):**
```json
{
  "error": "Store not active or invalid product URL"
}
```

---

## Transaction Endpoints

### GET /api/transactions
Get user transaction history

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `status` (optional): `pending|confirmed|cancelled|paid`
- `page` (optional): Pagination page number
- `limit` (optional): Items per page (default: 20)

**Response (200):**
```json
{
  "transactions": [
    {
      "id": "string",
      "store_name": "Amazon",
      "store_logo": "string",
      "order_id": "string",
      "purchase_amount": 2500.00,
      "cashback_amount": 125.00,
      "status": "pending|confirmed|cancelled|paid",
      "created_at": "2025-12-15T10:30:00Z",
      "confirmed_at": "2025-12-16T10:30:00Z (nullable)",
      "paid_at": "2025-12-17T10:30:00Z (nullable)"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 95
  }
}
```

---

### GET /api/transactions/{transaction_id}
Get transaction details

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "id": "string",
  "store_name": "string",
  "store_logo": "string",
  "order_id": "string",
  "click_id": "string",
  "purchase_amount": 2500.00,
  "cashback_amount": 125.00,
  "cashback_rate": "5%",
  "status": "pending|confirmed|cancelled|paid",
  "status_description": "Waiting for return period to end",
  "created_at": "2025-12-15T10:30:00Z",
  "confirmed_at": "nullable",
  "paid_at": "nullable",
  "cancelled_reason": "nullable"
}
```

---

## Wallet / Withdrawal Endpoints

### GET /api/wallet
Get wallet details

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "balance": {
    "total_earned": 1250.50,
    "pending": 450.00,
    "available": 800.50,
    "withdrawn": 500.00
  },
  "recent_withdrawals": [
    {
      "id": "string",
      "amount": 300.00,
      "status": "pending|processing|completed|failed",
      "upi_id": "user@upi",
      "requested_at": "2025-12-14T10:00:00Z",
      "completed_at": "2025-12-15T12:00:00Z (nullable)"
    }
  ]
}
```

---

### POST /api/withdraw
Request withdrawal

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "amount": 500.00,
  "method": "upi|bank",
  "upi_id": "string (required if method=upi)",
  "bank_details": {
    "account_number": "string",
    "ifsc": "string",
    "account_holder_name": "string"
  }
}
```

**Response (200):**
```json
{
  "withdrawal_id": "string",
  "amount": 500.00,
  "status": "pending",
  "message": "Withdrawal request submitted. You will receive money within 3-5 business days.",
  "requested_at": "2025-12-17T10:00:00Z"
}
```

**Error (400):**
```json
{
  "error": "Insufficient balance or amount below minimum threshold (₹50)"
}
```

---

## Profile Endpoints

### GET /api/profile
Get user profile

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "joined_at": "2025-01-01T00:00:00Z"
  },
  "payment_methods": [
    {
      "id": "string",
      "type": "upi|bank",
      "upi_id": "string (if upi)",
      "bank_account_last4": "string (if bank)",
      "is_default": boolean
    }
  ]
}
```

---

### PUT /api/profile
Update user profile

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "name": "string (optional)",
  "phone": "string (optional)"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string"
  }
}
```

---

## Error Response Format

All endpoints may return error responses:

**Response (400/401/404/500):**
```json
{
  "error": "Error message string",
  "code": "ERROR_CODE"
}
```

**Common Error Codes:**
- `UNAUTHORIZED`: Invalid or expired token
- `VALIDATION_ERROR`: Invalid request data
- `STORE_INACTIVE`: Store is not active
- `INSUFFICIENT_BALANCE`: Cannot withdraw
- `TRANSACTION_NOT_FOUND`: Invalid transaction ID

---

**Notes:**
- All timestamps are in ISO 8601 format (UTC)
- Currency amounts are in INR (Indian Rupees)
- All responses include appropriate HTTP status codes
- Rate limiting may apply (check `X-RateLimit-*` headers)
