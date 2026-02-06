import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from './AuthContext'

export function RequireAdmin({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const { token, adminVerified, verifying, accessDenied } = useAuth()

  if (!token) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  if (accessDenied) {
    return <Navigate to="/access-denied" replace />
  }

  if (!adminVerified) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-6">
        <div className="text-sm font-semibold text-slate-900">Checking admin access…</div>
        <div className="mt-1 text-sm text-slate-600">
          {verifying ? 'Verifying token with server.' : 'Please wait.'}
        </div>
      </div>
    )
  }

  return <>{children}</>
}
