const envBase = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim()

// In local dev, we want a safe default that doesn't accidentally hit production.
// When the panel is deployed, set VITE_API_BASE_URL explicitly (e.g. https://api.kashandaz.com).
export const API_BASE_URL =
  envBase ||
  (typeof window !== 'undefined'
    ? `${window.location.protocol}//${window.location.hostname}:8000`
    : 'http://127.0.0.1:8000')

export const API_PREFIX = '/api'
export const ADMIN_PREFIX = `${API_PREFIX}/admin`

export function buildApiUrl(path: string): string {
  const base = API_BASE_URL.replace(/\/$/, '')
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `${base}${normalized}`
}
