import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { useNavigate } from 'react-router-dom'
import { login as loginApi, logout as logoutApi } from '../api/auth'
import { adminApi } from '../api/admin'
import { ApiError } from '../api/errors'
import type { UserOut } from '../api/types'
import {
  clearAllAuth,
  loadAdminVerified,
  loadToken,
  loadUser,
  saveAdminVerified,
  saveToken,
  saveUser,
} from './authStorage'

export type AuthState = {
  token: string | null
  user: UserOut | null
  adminVerified: boolean
  verifying: boolean
  accessDenied: boolean
}

type AuthContextValue = AuthState & {
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  ensureAdminVerified: (tokenOverride?: string) => Promise<boolean>
  handleApiError: (err: unknown) => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const navigate = useNavigate()

  const [token, setToken] = useState<string | null>(() => loadToken())
  const [user, setUser] = useState<UserOut | null>(() => loadUser())
  const [adminVerified, setAdminVerified] = useState<boolean>(() => loadAdminVerified())
  const [verifying, setVerifying] = useState(false)
  const [accessDenied, setAccessDenied] = useState(false)

  const verifyInFlight = useRef<Promise<boolean> | null>(null)

  const logout = useCallback(() => {
    const currentToken = token
    if (currentToken) {
      void logoutApi(currentToken).catch(() => {
        // Best-effort: clear local auth even if server is unavailable.
      })
    }
    clearAllAuth()
    setToken(null)
    setUser(null)
    setAdminVerified(false)
    setAccessDenied(false)
    navigate('/login', { replace: true })
  }, [navigate, token])

  const ensureAdminVerified = useCallback(async (tokenOverride?: string) => {
    const effectiveToken = tokenOverride ?? token
    if (!effectiveToken) return false
    if (adminVerified) return true

    if (verifyInFlight.current) return verifyInFlight.current

    setVerifying(true)
    setAccessDenied(false)

    const p = (async () => {
      try {
        await adminApi.dashboard(effectiveToken)
        setAdminVerified(true)
        saveAdminVerified(true)
        return true
      } catch (err) {
        if (err instanceof ApiError) {
          if (err.status === 401) {
            logout()
            return false
          }
          if (err.status === 403) {
            // Token may be valid but not admin.
            clearAllAuth()
            setToken(null)
            setUser(null)
            setAdminVerified(false)
            saveAdminVerified(false)
            setAccessDenied(true)
            navigate('/access-denied', { replace: true })
            return false
          }
        }
        return false
      } finally {
        setVerifying(false)
        verifyInFlight.current = null
      }
    })()

    verifyInFlight.current = p
    return p
  }, [adminVerified, logout, navigate, token])

  const login = useCallback(
    async (email: string, password: string) => {
      setAccessDenied(false)
      const res = await loginApi(email, password)

      saveToken(res.token)
      saveUser(res.user)
      saveAdminVerified(false)

      setToken(res.token)
      setUser(res.user)
      setAdminVerified(false)

      const ok = await ensureAdminVerified(res.token)
      if (ok) {
        navigate('/dashboard', { replace: true })
      }
    },
    [ensureAdminVerified, navigate],
  )

  const handleApiError = useCallback(
    (err: unknown) => {
      if (err instanceof ApiError) {
        if (err.status === 401) {
          logout()
          return
        }
        if (err.status === 403) {
          setAccessDenied(true)
          navigate('/access-denied')
          return
        }
      }
    },
    [logout, navigate],
  )

  // If we have a token but haven't verified admin yet, verify once on app load.
  useEffect(() => {
    if (token && !adminVerified) {
      void ensureAdminVerified()
    }
  }, [adminVerified, ensureAdminVerified, token])

  const value = useMemo<AuthContextValue>(
    () => ({
      token,
      user,
      adminVerified,
      verifying,
      accessDenied,
      login,
      logout,
      ensureAdminVerified,
      handleApiError,
    }),
    [
      token,
      user,
      adminVerified,
      verifying,
      accessDenied,
      login,
      logout,
      ensureAdminVerified,
      handleApiError,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
