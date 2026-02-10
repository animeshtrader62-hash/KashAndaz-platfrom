export type UserOut = {
  id: string
  name: string
  email: string
  phone?: string | null
  role?: string | null
  created_at?: string | null
}

export type TokenResponse = {
  token: string
  user: UserOut
}

export type Pagination = {
  current_page: number
  total_pages: number
  total_items: number
}

export type AdminStoreListItem = {
  id: string
  name: string
  logo_url?: string | null
  affiliate_base_url?: string | null
  is_active: boolean
  created_at?: string | null
}

export type AdminStoreCreate = {
  name: string
  logo_url?: string | null
  affiliate_base_url?: string | null
  cashback_rate: string
  cashback_type: string
  category?: string | null
  is_active: boolean
}

export type AdminStoreUpdate = Partial<AdminStoreCreate>

export type AdminStoresListResponse = {
  stores: AdminStoreListItem[]
  pagination: Pagination
}

export type OfferOut = {
  id: string
  store_id: string
  title: string
  description?: string | null
  affiliate_redirect_url: string
  cashback_text: string
  start_at: string
  end_at: string
  status: 'active' | 'inactive'
  created_by: string
  created_at: string
  updated_at?: string | null
}

export type AdminOffersListResponse = {
  offers: OfferOut[]
  pagination: Pagination
}

export type OfferCreate = {
  store_id: string
  title: string
  description?: string | null
  affiliate_redirect_url: string
  cashback_text: string
  start_at: string
  end_at: string
  status: 'active' | 'inactive'
}

export type OfferUpdate = Partial<Omit<OfferCreate, 'store_id'>> & {
  status?: 'active' | 'inactive'
}

export type BannerOut = {
  id: string
  offer_id: string
  image_url: string
  priority: number
  start_at: string
  end_at: string
  status: 'active' | 'inactive'
  created_by: string
  created_at: string
  updated_at?: string | null
}

export type AdminBannersListResponse = {
  banners: BannerOut[]
  pagination: Pagination
}

export type BannerCreate = {
  offer_id: string
  image_url: string
  priority: number
  start_at: string
  end_at: string
  status: 'active' | 'inactive'
}

export type BannerUpdate = Partial<BannerCreate>

export type AdminDashboardMetrics = {
  total_users: number
  total_orders: number
  pending_cashback: number
  confirmed_cashback: number
  paid_cashback: number
}

export type AdminDashboardResponse = {
  metrics: AdminDashboardMetrics
}

export type AdminUserWalletSummary = {
  total_earned: number
  pending: number
  available: number
  withdrawn: number
}

export type AdminUserListItem = {
  user_id: string
  email: string
  status: string
  wallet_summary: AdminUserWalletSummary
}

export type AdminUsersListResponse = {
  users: AdminUserListItem[]
  pagination: Pagination
}

export type AdminClaimOut = {
  id: string
  user_id: string
  store_id: string
  order_id: string
  description?: string | null
  screenshot_url?: string | null
  status: string
  created_at?: string | null
  resolved_at?: string | null
}

export type AdminClaimsListResponse = {
  claims: AdminClaimOut[]
  pagination: Pagination
}

export type AdminClaimAuditEvent = {
  id: string
  admin_id: string
  action: string
  created_at?: string | null
}

export type AdminClaimAuditResponse = {
  events: AdminClaimAuditEvent[]
}
