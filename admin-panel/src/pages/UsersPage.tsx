import { useCallback, useEffect, useMemo, useState } from 'react'
import { adminApi } from '../api/admin'
import type { AdminUserListItem, Pagination } from '../api/types'
import { ApiError } from '../api/errors'
import { useAuth } from '../auth/AuthContext'
import { SkeletonTable } from '../components/SkeletonTable'
import { Table } from '../components/Table'
import { useToast } from '../components/ToastProvider'

function clampPage(p: number, total: number) {
  if (!Number.isFinite(p) || p < 1) return 1
  if (!Number.isFinite(total) || total < 1) return 1
  return Math.min(total, Math.max(1, Math.trunc(p)))
}

export function UsersPage() {
  const { token, handleApiError } = useAuth()
  const toast = useToast()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [users, setUsers] = useState<AdminUserListItem[]>([])
  const [pagination, setPagination] = useState<Pagination | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const limit = 20

  const [busyUserId, setBusyUserId] = useState<string | null>(null)

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
      const res = await adminApi.listUsers(token, { search: search || undefined, page, limit })
      setUsers(res.users)
      setPagination(res.pagination)
    } catch (err) {
      handleApiError(err)
      setError(err instanceof ApiError ? err.message : 'Failed to load users')
    } finally {
      setLoading(false)
    }
  }, [handleApiError, limit, page, search, token])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = pagination?.total_pages ?? 1
  const currentPage = useMemo(() => clampPage(page, totalPages), [page, totalPages])

  const setBlocked = useCallback(
    async (u: AdminUserListItem, blocked: boolean) => {
      if (!token) return
      const confirmMsg = blocked
        ? `Block ${u.email}? This will prevent login and actions.`
        : `Unblock ${u.email}?`
      if (!window.confirm(confirmMsg)) return

      setBusyUserId(u.user_id)
      try {
        if (blocked) {
          await adminApi.blockUser(token, u.user_id)
          toast.info('User blocked')
        } else {
          await adminApi.unblockUser(token, u.user_id)
          toast.success('User unblocked')
        }
        await load()
      } catch (err) {
        handleApiError(err)
        toast.error(err instanceof ApiError ? err.message : 'Update failed')
      } finally {
        setBusyUserId(null)
      }
    },
    [handleApiError, load, toast, token],
  )

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Users</h2>
          <p className="mt-1 text-sm text-slate-600">Super admin only. Paginated, search is debounced.</p>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-4">
        <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Search (email or name)
        </label>
        <input
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          placeholder="e.g. ali@kashandaz.com"
          className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
        />
      </div>

      {loading ? (
        <SkeletonTable rows={8} cols={5} />
      ) : error ? (
        <div className="rounded-2xl border border-orange-600 bg-orange-50 p-5">
          <div className="text-sm font-semibold text-slate-900">Failed to load users</div>
          <div className="mt-1 text-sm text-slate-700">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            onClick={() => void load()}
          >
            Retry
          </button>
        </div>
      ) : users.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No users found</div>
          <div className="mt-1 text-sm text-slate-600">Try a different search.</div>
        </div>
      ) : (
        <>
          <Table columns={['Email', 'Status', 'Wallet', 'Actions']}>
            {users.map((u) => {
              const isBlocked = String(u.status).toLowerCase() === 'blocked'
              const busy = busyUserId === u.user_id
              return (
                <tr key={u.user_id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                    <div>{u.email}</div>
                    <div className="text-xs font-normal text-slate-500">{u.user_id}</div>
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700">
                    {isBlocked ? (
                      <span className="rounded-full bg-orange-50 px-2 py-1 text-xs font-semibold text-orange-600">Blocked</span>
                    ) : (
                      <span className="rounded-full bg-slate-50 px-2 py-1 text-xs font-semibold text-blue-600">Active</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700">
                    <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
                      <div className="text-slate-500">Earned</div>
                      <div className="text-slate-900 font-semibold">{u.wallet_summary.total_earned}</div>
                      <div className="text-slate-500">Pending</div>
                      <div className="text-slate-900 font-semibold">{u.wallet_summary.pending}</div>
                      <div className="text-slate-500">Available</div>
                      <div className="text-slate-900 font-semibold">{u.wallet_summary.available}</div>
                      <div className="text-slate-500">Withdrawn</div>
                      <div className="text-slate-900 font-semibold">{u.wallet_summary.withdrawn}</div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-sm">
                    <div className="flex flex-wrap gap-2">
                      {isBlocked ? (
                        <button
                          type="button"
                          disabled={busy}
                          className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                          onClick={() => void setBlocked(u, false)}
                        >
                          Unblock
                        </button>
                      ) : (
                        <button
                          type="button"
                          disabled={busy}
                          className="rounded-lg border border-orange-600 bg-orange-50 px-3 py-1.5 text-sm font-semibold text-orange-600 hover:bg-orange-50 disabled:opacity-50"
                          onClick={() => void setBlocked(u, true)}
                        >
                          Block
                        </button>
                      )}
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
    </div>
  )
}
