export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim() ||
  'https://api.kashandaz.com'

export const API_PREFIX = '/api'
export const ADMIN_PREFIX = `${API_PREFIX}/admin`

export function buildApiUrl(path: string): string {
  const base = API_BASE_URL.replace(/\/$/, '')
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `${base}${normalized}`
}
