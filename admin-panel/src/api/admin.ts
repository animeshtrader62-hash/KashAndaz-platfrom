import { ADMIN_PREFIX, buildApiUrl } from './config'
import { httpRequest, jsonBody } from './http'
import type {
  AdminBannersListResponse,
  AdminDashboardResponse,
  AdminOffersListResponse,
  AdminStoreCreate,
  AdminStoreListItem,
  AdminStoresListResponse,
  AdminStoreUpdate,
  BannerCreate,
  BannerOut,
  BannerUpdate,
  OfferCreate,
  OfferOut,
  OfferUpdate,
} from './types'

function clampInt(value: unknown, min: number, max: number, fallback: number): number {
  const n = typeof value === 'number' ? value : Number(value)
  if (!Number.isFinite(n)) return fallback
  return Math.min(max, Math.max(min, Math.trunc(n)))
}

function clampLimit100(value: unknown, fallback: number): number {
  return clampInt(value, 1, 100, fallback)
}

export const adminApi = {
  dashboard(token: string) {
    return httpRequest<AdminDashboardResponse>(buildApiUrl(`${ADMIN_PREFIX}/dashboard`), {
      method: 'GET',
    }, { token })
  },

  listStores(token: string, page = 1, limit = 50) {
    const safePage = clampInt(page, 1, 10_000, 1)
    // Backend stores endpoint allows up to 200.
    const safeLimit = clampInt(limit, 1, 200, 50)
    const qs = new URLSearchParams({ page: String(safePage), limit: String(safeLimit) })
    return httpRequest<AdminStoresListResponse>(
      buildApiUrl(`${ADMIN_PREFIX}/stores?${qs.toString()}`),
      { method: 'GET' },
      { token },
    )
  },

  createStore(token: string, payload: AdminStoreCreate) {
    return httpRequest<AdminStoreListItem>(buildApiUrl(`${ADMIN_PREFIX}/stores`), {
      method: 'POST',
      body: jsonBody(payload),
    }, { token })
  },

  updateStore(token: string, storeId: string, payload: AdminStoreUpdate) {
    return httpRequest<AdminStoreListItem>(buildApiUrl(`${ADMIN_PREFIX}/stores/${storeId}`), {
      method: 'PUT',
      body: jsonBody(payload),
    }, { token })
  },

  pauseStore(token: string, storeId: string) {
    return httpRequest<{ status: string; store_id: string; is_active: boolean }>(
      buildApiUrl(`${ADMIN_PREFIX}/stores/${storeId}/pause`),
      { method: 'POST' },
      { token },
    )
  },

  unpauseStore(token: string, storeId: string) {
    return httpRequest<{ status: string; store_id: string; is_active: boolean }>(
      buildApiUrl(`${ADMIN_PREFIX}/stores/${storeId}/unpause`),
      { method: 'POST' },
      { token },
    )
  },

  listOffers(token: string, params?: { store_id?: string; status?: string; page?: number; limit?: number }) {
    const qs = new URLSearchParams()
    if (params?.store_id) qs.set('store_id', params.store_id)
    if (params?.status) qs.set('status', params.status)
    qs.set('page', String(clampInt(params?.page, 1, 10_000, 1)))
    qs.set('limit', String(clampLimit100(params?.limit, 20)))
    return httpRequest<AdminOffersListResponse>(
      buildApiUrl(`${ADMIN_PREFIX}/offers?${qs.toString()}`),
      { method: 'GET' },
      { token },
    )
  },

  createOffer(token: string, payload: OfferCreate) {
    return httpRequest<OfferOut>(buildApiUrl(`${ADMIN_PREFIX}/offers`), {
      method: 'POST',
      body: jsonBody(payload),
    }, { token })
  },

  updateOffer(token: string, offerId: string, payload: OfferUpdate) {
    return httpRequest<OfferOut>(buildApiUrl(`${ADMIN_PREFIX}/offers/${offerId}`), {
      method: 'PUT',
      body: jsonBody(payload),
    }, { token })
  },

  setOfferStatus(token: string, offerId: string, status: 'active' | 'inactive') {
    return httpRequest<OfferOut>(buildApiUrl(`${ADMIN_PREFIX}/offers/${offerId}/status`), {
      method: 'PATCH',
      body: jsonBody({ status }),
    }, { token })
  },

  listBanners(token: string, params?: { offer_id?: string; status?: string; page?: number; limit?: number }) {
    const qs = new URLSearchParams()
    if (params?.offer_id) qs.set('offer_id', params.offer_id)
    if (params?.status) qs.set('status', params.status)
    qs.set('page', String(clampInt(params?.page, 1, 10_000, 1)))
    qs.set('limit', String(clampLimit100(params?.limit, 20)))

    return httpRequest<AdminBannersListResponse>(
      buildApiUrl(`${ADMIN_PREFIX}/banners?${qs.toString()}`),
      { method: 'GET' },
      { token },
    )
  },

  createBanner(token: string, payload: BannerCreate) {
    return httpRequest<BannerOut>(buildApiUrl(`${ADMIN_PREFIX}/banners`), {
      method: 'POST',
      body: jsonBody(payload),
    }, { token })
  },

  updateBanner(token: string, bannerId: string, payload: BannerUpdate) {
    return httpRequest<BannerOut>(buildApiUrl(`${ADMIN_PREFIX}/banners/${bannerId}`), {
      method: 'PUT',
      body: jsonBody(payload),
    }, { token })
  },

  setBannerStatus(token: string, bannerId: string, status: 'active' | 'inactive') {
    return httpRequest<BannerOut>(buildApiUrl(`${ADMIN_PREFIX}/banners/${bannerId}/status`), {
      method: 'PATCH',
      body: jsonBody({ status }),
    }, { token })
  },
}
