import { useCallback, useEffect, useMemo, useState } from 'react'
import { adminApi } from '../api/admin'
import type { AdminClaimAuditEvent, AdminClaimOut, Pagination } from '../api/types'
import { ApiError } from '../api/errors'
import { useAuth } from '../auth/AuthContext'
import { Modal } from '../components/Modal'
import { SkeletonTable } from '../components/SkeletonTable'
import { Table } from '../components/Table'
import { useToast } from '../components/ToastProvider'
import { formatDateShort } from '../utils/date'

function clampPage(p: number, total: number) {
  if (!Number.isFinite(p) || p < 1) return 1
  if (!Number.isFinite(total) || total < 1) return 1
  return Math.min(total, Math.max(1, Math.trunc(p)))
}

export function ClaimsPage() {
  const { token, user, handleApiError } = useAuth()
  const toast = useToast()

  const role = String(user?.role || '').toLowerCase()
  const canResolve = role === 'admin' || role === 'super_admin'

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [claims, setClaims] = useState<AdminClaimOut[]>([])
  const [pagination, setPagination] = useState<Pagination | null>(null)

  const [status, setStatus] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const limit = 20

  const [busyClaimId, setBusyClaimId] = useState<string | null>(null)

  const [approveOpen, setApproveOpen] = useState(false)
  const [approveClaim, setApproveClaim] = useState<AdminClaimOut | null>(null)
  const [creditAmount, setCreditAmount] = useState('')

  const [auditOpen, setAuditOpen] = useState(false)
  const [auditClaim, setAuditClaim] = useState<AdminClaimOut | null>(null)
  const [auditLoading, setAuditLoading] = useState(false)
  const [auditError, setAuditError] = useState<string | null>(null)
  const [auditEvents, setAuditEvents] = useState<AdminClaimAuditEvent[]>([])

  useEffect(() => {
    const id = window.setTimeout(() => {
      const s = searchInput.trim()
      setPage(1)
      setSearch(s)
    }, 300)
    return () => window.clearTimeout(id)
  }, [searchInput])

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const res = await adminApi.listClaims(token, {
        status: status || undefined,
        search: search || undefined,
        page,
        limit,
      })
      setClaims(res.claims)
      setPagination(res.pagination)
    } catch (err) {
      handleApiError(err)
      setError(err instanceof ApiError ? err.message : 'Failed to load claims')
    } finally {
      setLoading(false)
    }
  }, [handleApiError, limit, page, search, status, token])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = pagination?.total_pages ?? 1
  const currentPage = useMemo(() => clampPage(page, totalPages), [page, totalPages])

  const openApprove = useCallback(
    (c: AdminClaimOut) => {
      setApproveClaim(c)
      setCreditAmount('')
      setApproveOpen(true)
    },
    [],
  )

  const submitApprove = useCallback(async () => {
    if (!token || !approveClaim) return
    const amt = Number(creditAmount)
    if (!Number.isFinite(amt) || amt <= 0) {
      toast.error('Enter a valid credit amount')
      return
    }

    if (!window.confirm(`Approve claim ${approveClaim.id} with credit_amount=${amt}?`)) return

    setBusyClaimId(approveClaim.id)
    try {
      await adminApi.approveClaim(token, approveClaim.id, amt)
      toast.success('Claim approved')
      setApproveOpen(false)
      await load()
    } catch (err) {
      handleApiError(err)
      toast.error(err instanceof ApiError ? err.message : 'Approve failed')
    } finally {
      setBusyClaimId(null)
    }
  }, [approveClaim, creditAmount, handleApiError, load, toast, token])

  const reject = useCallback(
    async (c: AdminClaimOut) => {
      if (!token) return
      if (!window.confirm(`Reject claim ${c.id}?`)) return
      setBusyClaimId(c.id)
      try {
        await adminApi.rejectClaim(token, c.id)
        toast.info('Claim rejected')
        await load()
      } catch (err) {
        handleApiError(err)
        toast.error(err instanceof ApiError ? err.message : 'Reject failed')
      } finally {
        setBusyClaimId(null)
      }
    },
    [handleApiError, load, toast, token],
  )

  const openAudit = useCallback(
    async (c: AdminClaimOut) => {
      if (!token) return
      setAuditClaim(c)
      setAuditOpen(true)
      setAuditLoading(true)
      setAuditError(null)
      setAuditEvents([])
      try {
        const res = await adminApi.claimAudit(token, c.id)
        setAuditEvents(res.events)
      } catch (err) {
        handleApiError(err)
        setAuditError(err instanceof ApiError ? err.message : 'Failed to load audit history')
      } finally {
        setAuditLoading(false)
      }
    },
    [handleApiError, token],
  )

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Claims / Missing Cashback</h2>
          <p className="mt-1 text-sm text-slate-600">
            View claims (viewer/admin/super_admin). Approve/reject (admin/super_admin).
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
        <div className="rounded-2xl border border-slate-200 bg-white p-4">
          <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Status</label>
          <select
            value={status}
            onChange={(e) => {
              setPage(1)
              setStatus(e.target.value)
            }}
            className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900"
          >
            <option value="">All</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-4 md:col-span-2">
          <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Search</label>
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Order ID or User ID"
            className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
          />
        </div>
      </div>

      {loading ? (
        <SkeletonTable rows={8} cols={6} />
      ) : error ? (
        <div className="rounded-2xl border border-orange-600 bg-orange-50 p-5">
          <div className="text-sm font-semibold text-slate-900">Failed to load claims</div>
          <div className="mt-1 text-sm text-slate-700">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            onClick={() => void load()}
          >
            Retry
          </button>
        </div>
      ) : claims.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No claims</div>
          <div className="mt-1 text-sm text-slate-600">Nothing matches the current filters.</div>
        </div>
      ) : (
        <>
          <Table columns={['Order', 'User', 'Store', 'Status', 'Created', 'Actions']}>
            {claims.map((c) => {
              const st = String(c.status).toLowerCase()
              const busy = busyClaimId === c.id
              return (
                <tr key={c.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                    <div>{c.order_id}</div>
                    <div className="text-xs font-normal text-slate-500">{c.id}</div>
                    {c.screenshot_url ? (
                      <a
                        className="mt-1 inline-block text-xs font-semibold text-slate-700 underline"
                        href={c.screenshot_url}
                        target="_blank"
                        rel="noreferrer"
                      >
                        Screenshot
                      </a>
                    ) : null}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700 break-all">{c.user_id}</td>
                  <td className="px-4 py-3 text-sm text-slate-700 break-all">{c.store_id}</td>
                  <td className="px-4 py-3 text-sm">
                    {st === 'pending' ? (
                      <span className="rounded-full bg-orange-50 px-2 py-1 text-xs font-semibold text-orange-600">Pending</span>
                    ) : st === 'approved' ? (
                      <span className="rounded-full bg-slate-50 px-2 py-1 text-xs font-semibold text-blue-600">Approved</span>
                    ) : (
                      <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700">Rejected</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700">{formatDateShort(c.created_at)}</td>
                  <td className="px-4 py-3 text-sm">
                    <div className="flex flex-wrap gap-2">
                      <button
                        type="button"
                        className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                        onClick={() => void openAudit(c)}
                      >
                        Audit
                      </button>

                      {canResolve && st === 'pending' ? (
                        <>
                          <button
                            type="button"
                            disabled={busy}
                            className="rounded-lg bg-blue-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
                            onClick={() => openApprove(c)}
                          >
                            Approve
                          </button>
                          <button
                            type="button"
                            disabled={busy}
                            className="rounded-lg border border-orange-600 bg-orange-50 px-3 py-1.5 text-sm font-semibold text-orange-600 hover:bg-orange-50 disabled:opacity-50"
                            onClick={() => void reject(c)}
                          >
                            Reject
                          </button>
                        </>
                      ) : null}
                    </div>
                  </td>
                </tr>
              )
            })}
          </Table>

          <div className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3">
            <div className="text-sm text-slate-600">
              Page <span className="font-semibold text-slate-900">{currentPage}</span> of{' '}
              <span className="font-semibold text-slate-900">{totalPages}</span>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                disabled={currentPage <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
              >
                Prev
              </button>
              <button
                type="button"
                className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                disabled={currentPage >= totalPages}
                onClick={() => setPage((p) => p + 1)}
              >
                Next
              </button>
            </div>
          </div>
        </>
      )}

      <Modal
        open={approveOpen}
        onClose={() => {
          setApproveOpen(false)
        }}
        title="Approve claim"
      >
        <div className="space-y-3">
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm text-slate-700">
            Claim: <span className="font-semibold text-slate-900">{approveClaim?.id}</span>
          </div>
          <div>
            <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Credit amount</label>
            <input
              value={creditAmount}
              onChange={(e) => setCreditAmount(e.target.value)}
              placeholder="e.g. 100"
              inputMode="decimal"
              className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
            />
          </div>
          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
              onClick={() => setApproveOpen(false)}
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={!approveClaim}
              className="rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              onClick={() => void submitApprove()}
            >
              Approve
            </button>
          </div>
        </div>
      </Modal>

      <Modal
        open={auditOpen}
        onClose={() => {
          setAuditOpen(false)
        }}
        title="Audit history"
      >
        <div className="space-y-3">
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm text-slate-700">
            Claim: <span className="font-semibold text-slate-900">{auditClaim?.id}</span>
          </div>

          {auditLoading ? (
            <div className="text-sm text-slate-600">Loading…</div>
          ) : auditError ? (
            <div className="rounded-xl border border-orange-600 bg-orange-50 p-3 text-sm text-slate-700">
              {auditError}
            </div>
          ) : auditEvents.length === 0 ? (
            <div className="text-sm text-slate-600">No audit events for this claim yet.</div>
          ) : (
            <div className="max-h-[50vh] overflow-auto rounded-xl border border-slate-200">
              <table className="w-full text-left text-sm">
                <thead className="sticky top-0 bg-white">
                  <tr className="border-b border-slate-200 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th className="px-3 py-2">When</th>
                    <th className="px-3 py-2">Admin</th>
                    <th className="px-3 py-2">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {auditEvents.map((e) => (
                    <tr key={e.id} className="border-b border-slate-100 last:border-b-0">
                      <td className="px-3 py-2 text-slate-700">{formatDateShort(e.created_at)}</td>
                      <td className="px-3 py-2 text-slate-700 break-all">{e.admin_id}</td>
                      <td className="px-3 py-2 text-slate-900 break-all font-medium">{e.action}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <div className="flex items-center justify-end">
            <button
              type="button"
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
              onClick={() => setAuditOpen(false)}
            >
              Close
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
