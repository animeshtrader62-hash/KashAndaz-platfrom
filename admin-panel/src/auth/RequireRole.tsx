import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from './AuthContext'

export function RequireRole({
  allowed,
  children,
}: {
  allowed: string[]
  children: React.ReactNode
}) {
  const location = useLocation()
  const { user } = useAuth()

  const role = String(user?.role || '').toLowerCase()
  const ok = allowed.map((r) => r.toLowerCase()).includes(role)

  if (!ok) {
    return <Navigate to="/access-denied" replace state={{ from: location.pathname }} />
  }

  return <>{children}</>
}
