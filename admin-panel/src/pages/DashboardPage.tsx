import { useCallback, useEffect, useState } from 'react'
import { adminApi } from '../api/admin'
import type { AdminDashboardMetrics } from '../api/types'
import { ApiError } from '../api/errors'
import { useAuth } from '../auth/AuthContext'
import { MetricCard } from '../components/MetricCard'
import { SkeletonTable } from '../components/SkeletonTable'
import { useToast } from '../components/ToastProvider'
import { formatInr } from '../utils/money'

export function DashboardPage() {
  const { token, handleApiError } = useAuth()
  const toast = useToast()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [metrics, setMetrics] = useState<AdminDashboardMetrics | null>(null)

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const res = await adminApi.dashboard(token)
      setMetrics(res.metrics)
    } catch (err) {
      handleApiError(err)
      const msg = err instanceof ApiError ? err.message : 'Failed to load dashboard'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [handleApiError, token])

  useEffect(() => {
    void load()
  }, [load])

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-900">Dashboard</h2>
        <p className="mt-1 text-sm text-slate-600">Live metrics (read-only).</p>
      </div>

      {loading ? (
        <SkeletonTable rows={4} cols={4} />
      ) : error ? (
        <div className="rounded-2xl border border-orange-600 bg-orange-50 p-5">
          <div className="text-sm font-semibold text-slate-900">Failed to load metrics</div>
          <div className="mt-1 text-sm text-slate-700">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            onClick={() => {
              toast.info('Refreshing…')
              void load()
            }}
          >
            Retry
          </button>
        </div>
      ) : metrics ? (
        <>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
            <MetricCard
              title="Total Users"
              value={metrics.total_users.toLocaleString()}
              titleHint="Counts reflect actual database users"
            />
            <MetricCard title="Total Orders" value={metrics.total_orders.toLocaleString()} subtitle="All-time" />
            <MetricCard title="Pending Cashback" value={formatInr(metrics.pending_cashback)} subtitle="Awaiting confirmation" />
            <MetricCard title="Confirmed Cashback" value={formatInr(metrics.confirmed_cashback)} subtitle="Confirmed" />
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6">
            <div className="text-sm font-semibold text-slate-900">Paid cashback</div>
            <div className="mt-1 text-2xl font-bold text-slate-900">{formatInr(metrics.paid_cashback)}</div>
            <div className="mt-1 text-sm text-slate-600">Charts are not available in this view.</div>
          </div>
        </>
      ) : (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No metrics</div>
          <div className="mt-1 text-sm text-slate-600">No data returned from server.</div>
        </div>
      )}
    </div>
  )
}
