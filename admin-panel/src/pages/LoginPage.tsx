import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { ApiError } from '../api/errors'
import { useToast } from '../components/ToastProvider'
import { API_BASE_URL } from '../api/config'

export function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const toast = useToast()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto flex min-h-screen max-w-[1200px] items-center justify-center px-4">
        <div className="w-full max-w-md">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="text-sm font-semibold uppercase tracking-wide text-slate-500">
              KashAndaz
            </div>
            <h1 className="mt-1 text-2xl font-bold text-slate-900">Admin Login</h1>
            <p className="mt-2 text-sm text-slate-600">
              Sign in with an admin account.
            </p>

            <div className="mt-6 space-y-4">
              <label className="block">
                <div className="mb-1 text-sm font-semibold text-slate-700">Email</div>
                <input
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  type="email"
                  placeholder="admin@kashandaz.com"
                  className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none ring-0 focus:border-slate-400"
                />
              </label>
              <label className="block">
                <div className="mb-1 text-sm font-semibold text-slate-700">Password</div>
                <input
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  type="password"
                  placeholder="••••••••"
                  className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none ring-0 focus:border-slate-400"
                />
              </label>

              <button
                type="button"
                disabled={submitting}
                className="w-full rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-60"
                onClick={() => {
                  setError(null)
                  const e = email.trim()
                  const p = password.trim()
                  if (!e || !p) {
                    setError('Email and password are required')
                    return
                  }

                  setSubmitting(true)
                  void (async () => {
                    try {
                      await login(e, p)
                      toast.success('Logged in')
                      navigate('/dashboard', { replace: true })
                    } catch (err) {
                      if (err instanceof ApiError) {
                        setError(err.message)
                        toast.error(err.message)
                      } else {
                        setError('Login failed')
                        toast.error('Login failed')
                      }
                    } finally {
                      setSubmitting(false)
                    }
                  })()
                }}
              >
                {submitting ? 'Signing in…' : 'Login'}
              </button>
            </div>

            {error ? (
              <div className="mt-4 rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-900">
                {error}
              </div>
            ) : null}

            <div className="mt-4 text-xs text-slate-500">
              Uses `POST /api/auth/login` and verifies admin access.
              <div className="mt-1">
                API Base: <span className="font-mono">{API_BASE_URL}</span>
              </div>
              <div className="mt-1">
                Login URL:{' '}
                <span className="font-mono">{`${API_BASE_URL}/api/auth/login`}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
