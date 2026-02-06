import type { UserOut } from '../api/types'

const TOKEN_KEY = 'ka_admin_token'
const USER_KEY = 'ka_admin_user'
const ADMIN_VERIFIED_KEY = 'ka_admin_verified'

export function loadToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function saveToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token)
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
}

export function loadUser(): UserOut | null {
  const raw = localStorage.getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as UserOut
  } catch {
    return null
  }
}

export function saveUser(user: UserOut) {
  localStorage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearUser() {
  localStorage.removeItem(USER_KEY)
}

export function loadAdminVerified(): boolean {
  return localStorage.getItem(ADMIN_VERIFIED_KEY) === '1'
}

export function saveAdminVerified(value: boolean) {
  localStorage.setItem(ADMIN_VERIFIED_KEY, value ? '1' : '0')
}

export function clearAdminVerified() {
  localStorage.removeItem(ADMIN_VERIFIED_KEY)
}

export function clearAllAuth() {
  clearToken()
  clearUser()
  clearAdminVerified()
}
