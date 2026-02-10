import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { API_BASE_URL } from '../api/config'
import { ApiError } from '../api/errors'
import { useToast } from '../components/ToastProvider'

export function ResetPasswordPage() {
  const toast = useToast()
  const [params] = useSearchParams()
  const token = useMemo(() => params.get('token') || '', [params])

  const [newPassword, setNewPassword] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState(false)

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto flex min-h-screen max-w-[1200px] items-center justify-center px-4">
        <div className="w-full max-w-md">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="text-sm font-semibold uppercase tracking-wide text-slate-500">KashAndaz</div>
            <h1 className="mt-1 text-2xl font-bold text-slate-900">Set New Password</h1>
            <p className="mt-2 text-sm text-slate-600">
              Password must be at least 12 characters and include uppercase, lowercase, number, and symbol.
            </p>

            <div className="mt-6 space-y-4">
              <label className="block">
                <div className="mb-1 text-sm font-semibold text-slate-700">New password</div>
                <input
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  type="password"
                  className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none ring-0 focus:border-blue-600"
                />
              </label>

              <button
                type="button"
                disabled={submitting}
                className="w-full rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
                onClick={() => {
                  setError(null)
                  const p = newPassword.trim()
                  if (!token) {
                    setError('Missing reset token')
                    return
                  }
                  if (!p) {
                    setError('New password is required')
                    return
                  }

                  setSubmitting(true)
                  void (async () => {
                    try {
                      const res = await fetch(`${API_BASE_URL}/api/admin/auth/password-reset/confirm`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ token, new_password: p }),
                      })
                      if (!res.ok) {
                        const data = (await res.json().catch(() => null)) as { detail?: string } | null
                        throw new ApiError(res.status, data?.detail || 'Reset failed')
                      }
                      setDone(true)
                      toast.success('Password reset. Please log in again.')
                    } catch (err) {
                      if (err instanceof ApiError) {
                        setError(err.message)
                        toast.error(err.message)
                      } else {
                        setError('Reset failed')
                        toast.error('Reset failed')
                      }
                    } finally {
                      setSubmitting(false)
                    }
                  })()
                }}
              >
                {submitting ? 'Resetting…' : 'Reset Password'}
              </button>
            </div>

            {done ? (
              <div className="mt-4 rounded-xl border border-blue-600 bg-white p-3 text-sm text-slate-900">
                Password updated. Go to login.
              </div>
            ) : null}

            {error ? (
              <div className="mt-4 rounded-xl border border-orange-600 bg-orange-50 p-3 text-sm text-slate-900">
                {error}
              </div>
            ) : null}

            <div className="mt-4 text-sm">
              <Link className="font-semibold text-slate-900 hover:underline" to="/login">
                Back to login
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
