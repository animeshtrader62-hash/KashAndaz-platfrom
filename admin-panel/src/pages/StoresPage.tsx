import { useCallback, useEffect, useMemo, useState } from 'react'
import { adminApi } from '../api/admin'
import type { AdminStoreCreate, AdminStoreListItem, AdminStoreUpdate } from '../api/types'
import { ApiError } from '../api/errors'
import { useAuth } from '../auth/AuthContext'
import { Modal } from '../components/Modal'
import { SafeImage } from '../components/SafeImage'
import { SkeletonTable } from '../components/SkeletonTable'
import { StatusBadge } from '../components/StatusBadge'
import { Table } from '../components/Table'
import { useToast } from '../components/ToastProvider'
import { formatDateShort } from '../utils/date'
import { validateDirectImageUrl } from '../utils/imageUrl'

type StoreEditorMode = 'create' | 'edit'

const STORE_CATEGORIES = [
  { value: '', label: '(none)' },
  { value: 'fashion', label: 'fashion' },
  { value: 'electronics', label: 'electronics' },
  { value: 'beauty', label: 'beauty' },
  { value: 'travel', label: 'travel' },
  { value: 'food', label: 'food' },
  { value: 'home', label: 'home' },
  { value: 'finance', label: 'finance' },
  { value: 'groceries', label: 'groceries' },
  { value: 'other', label: 'other' },
] as const

export function StoresPage() {
  const { token, handleApiError } = useAuth()
  const toast = useToast()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [stores, setStores] = useState<AdminStoreListItem[]>([])

  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<StoreEditorMode>('create')
  const [editingStore, setEditingStore] = useState<AdminStoreListItem | null>(null)

  const [formName, setFormName] = useState('')
  const [formSlug, setFormSlug] = useState('')
  const [formLogoUrl, setFormLogoUrl] = useState('')
  const [formAffiliateBaseUrl, setFormAffiliateBaseUrl] = useState('')
  const [formCashbackRate, setFormCashbackRate] = useState('')
  const [formCashbackType, setFormCashbackType] = useState('percentage')
  const [formPopularityScore, setFormPopularityScore] = useState('0')
  const [formFeaturedStore, setFormFeaturedStore] = useState(false)
  const [formCategory, setFormCategory] = useState('')
  const [formIsActive, setFormIsActive] = useState(true)

  const logoValidation = useMemo(() => {
    const v = formLogoUrl.trim()
    if (!v) {
      if (editorMode === 'create') return { ok: false, reason: 'Logo URL is required.' } as const
      return { ok: true } as const
    }
    return validateDirectImageUrl(v, { requireHttps: true })
  }, [editorMode, formLogoUrl])

  const cashbackRateValidation = useMemo(() => {
    const v = formCashbackRate.trim()
    if (!v) {
      if (editorMode === 'create') return { ok: false, reason: 'Cashback rate is required.' } as const
      return { ok: true } as const
    }

    if (v.includes('%')) return { ok: false, reason: 'Enter a number only (do not include %).' } as const

    const n = Number(v)
    if (!Number.isFinite(n)) return { ok: false, reason: 'Cashback rate must be a valid number.' } as const
    if (n < 0) return { ok: false, reason: 'Cashback rate must be >= 0.' } as const
    if (formCashbackType === 'percentage' && n > 100)
      return { ok: false, reason: 'Percentage cashback rate must be <= 100.' } as const
    return { ok: true } as const
  }, [editorMode, formCashbackRate, formCashbackType])

  const popularityValidation = useMemo(() => {
    const v = formPopularityScore.trim()
    if (!v) return { ok: true } as const
    const n = Number(v)
    if (!Number.isFinite(n)) return { ok: false, reason: 'Popularity score must be a number.' } as const
    if (n < 0) return { ok: false, reason: 'Popularity score must be >= 0.' } as const
    if (!Number.isInteger(n)) return { ok: false, reason: 'Popularity score must be an integer.' } as const
    return { ok: true } as const
  }, [formPopularityScore])

  const canSubmit = useMemo(() => {
    if (!formName.trim()) return false
    if (editorMode === 'create' && !formCashbackType.trim()) return false
    if (!logoValidation.ok) return false
    if (!cashbackRateValidation.ok) return false
    if (!popularityValidation.ok) return false
    return true
  }, [cashbackRateValidation.ok, editorMode, formCashbackType, formName, logoValidation.ok, popularityValidation.ok])

  const resetForm = useCallback(() => {
    setFormName('')
    setFormSlug('')
    setFormLogoUrl('')
    setFormAffiliateBaseUrl('')
    setFormCashbackRate('')
    setFormCashbackType('percentage')
    setFormPopularityScore('0')
    setFormFeaturedStore(false)
    setFormCategory('')
    setFormIsActive(true)
  }, [])

  const openCreate = useCallback(() => {
    setEditorMode('create')
    setEditingStore(null)
    resetForm()
    setEditorOpen(true)
  }, [resetForm])

  const openEdit = useCallback((s: AdminStoreListItem) => {
    setEditorMode('edit')
    setEditingStore(s)
    setFormName(s.name ?? '')
    setFormSlug(s.store_slug ?? '')
    setFormLogoUrl(s.logo_url ?? '')
    setFormAffiliateBaseUrl(s.affiliate_base_url ?? '')
    setFormIsActive(!!s.is_active)
    setFormCashbackRate(s.cashback_rate != null ? String(s.cashback_rate) : '')
    setFormCashbackType((s.cashback_type as string) || 'percentage')
    setFormPopularityScore(String(s.popularity_score ?? 0))
    setFormFeaturedStore(!!s.featured_store)
    setFormCategory((s.category as string) || '')
    setEditorOpen(true)
  }, [])

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const res = await adminApi.listStores(token)
      setStores(res.stores)
    } catch (err) {
      handleApiError(err)
      const message = err instanceof ApiError ? err.message : 'Failed to load stores'
      setError(message)
    } finally {
      setLoading(false)
    }
  }, [handleApiError, token])

  useEffect(() => {
    void load()
  }, [load])

  const submit = useCallback(async () => {
    if (!token) return
    try {
      if (editorMode === 'create') {
        const payload: AdminStoreCreate = {
          name: formName.trim(),
          store_slug: formSlug.trim() ? formSlug.trim() : null,
          logo_url: formLogoUrl.trim(),
          affiliate_base_url: formAffiliateBaseUrl.trim() ? formAffiliateBaseUrl.trim() : null,
          cashback_rate: formCashbackRate.trim(),
          cashback_type: formCashbackType.trim(),
          popularity_score: formPopularityScore.trim() ? Number(formPopularityScore.trim()) : 0,
          featured_store: formFeaturedStore,
          category: formCategory.trim() ? formCategory.trim() : null,
          is_active: formIsActive,
        }
        await adminApi.createStore(token, payload)
        toast.success('Store created')
      } else {
        if (!editingStore) return
        const payload: AdminStoreUpdate = {
          name: formName.trim() ? formName.trim() : undefined,
          store_slug: formSlug.trim() ? formSlug.trim() : undefined,
          logo_url: formLogoUrl.trim() ? formLogoUrl.trim() : undefined,
          affiliate_base_url: formAffiliateBaseUrl.trim() ? formAffiliateBaseUrl.trim() : undefined,
          cashback_rate: formCashbackRate.trim() ? formCashbackRate.trim() : undefined,
          cashback_type: formCashbackType.trim() ? formCashbackType.trim() : undefined,
          popularity_score: formPopularityScore.trim() ? Number(formPopularityScore.trim()) : undefined,
          featured_store: formFeaturedStore,
          category: formCategory.trim() ? formCategory.trim() : undefined,
          is_active: formIsActive,
        }
        await adminApi.updateStore(token, editingStore.id, payload)
        toast.success('Store updated')
      }
      setEditorOpen(false)
      await load()
    } catch (err) {
      handleApiError(err)
      toast.error(err instanceof ApiError ? err.message : 'Save failed')
    }
  }, [
    editingStore,
    editorMode,
    formAffiliateBaseUrl,
    formCashbackRate,
    formCashbackType,
    formCategory,
    formIsActive,
    formLogoUrl,
    formName,
    handleApiError,
    load,
    toast,
    token,
  ])

  const toggleActive = useCallback(
    async (s: AdminStoreListItem) => {
      if (!token) return
      try {
        if (s.is_active) {
          const res = await adminApi.pauseStore(token, s.id)
          setStores((prev) => prev.map((x) => (x.id === s.id ? { ...x, is_active: res.is_active } : x)))
          toast.info('Store paused')
        } else {
          const res = await adminApi.unpauseStore(token, s.id)
          setStores((prev) => prev.map((x) => (x.id === s.id ? { ...x, is_active: res.is_active } : x)))
          toast.info('Store unpaused')
        }
      } catch (err) {
        handleApiError(err)
        toast.error(err instanceof ApiError ? err.message : 'Update failed')
      }
    },
    [handleApiError, toast, token],
  )

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Stores</h2>
          <p className="mt-1 text-sm text-slate-600">Manage stores (active + inactive).</p>
        </div>
        <button
          type="button"
          className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
          onClick={openCreate}
        >
          + Add Store
        </button>
      </div>

      {loading ? (
        <SkeletonTable rows={8} cols={5} />
      ) : error ? (
        <div className="rounded-2xl border border-orange-600 bg-orange-50 p-5">
          <div className="text-sm font-semibold text-slate-900">Failed to load stores</div>
          <div className="mt-1 text-sm text-slate-700">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            onClick={() => void load()}
          >
            Retry
          </button>
        </div>
      ) : stores.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No stores</div>
          <div className="mt-1 text-sm text-slate-600">Create your first store to get started.</div>
        </div>
      ) : (
        <Table columns={['Name', 'Affiliate base URL', 'Created', 'Status', 'Actions']}>
          {stores.map((s) => (
            <tr key={s.id} className="hover:bg-slate-50">
              <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                <div className="flex items-center gap-3">
                  <SafeImage
                    src={s.logo_url}
                    alt={s.name}
                    className="h-10 w-10 overflow-hidden rounded-md border border-slate-200 bg-white"
                    imgClassName="h-10 w-10 object-contain p-1"
                    fallbackClassName="flex h-full w-full items-center justify-center bg-white text-slate-300"
                  />
                  <div>
                    <div>{s.name}</div>
                    <div className="text-xs font-normal text-slate-500">{s.id}</div>
                  </div>
                </div>
              </td>
              <td className="px-4 py-3 text-sm text-slate-700 break-all">{s.affiliate_base_url ?? '-'}</td>
              <td className="px-4 py-3 text-sm text-slate-700">{formatDateShort(s.created_at)}</td>
              <td className="px-4 py-3 text-sm">
                <StatusBadge active={s.is_active} />
              </td>
              <td className="px-4 py-3 text-sm">
                <div className="flex flex-wrap gap-2">
                  <button
                    type="button"
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                    onClick={() => openEdit(s)}
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    className={
                      'rounded-lg px-3 py-1.5 text-sm font-semibold ' +
                      (s.is_active
                        ? 'border border-orange-600 bg-orange-50 text-orange-600 hover:bg-orange-50'
                        : 'border border-blue-600 bg-white text-blue-600 hover:bg-slate-50')
                    }
                    onClick={() => void toggleActive(s)}
                  >
                    {s.is_active ? 'Pause' : 'Unpause'}
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </Table>
      )}

      <Modal
        open={editorOpen}
        title={editorMode === 'create' ? 'Create store' : 'Edit store'}
        onClose={() => setEditorOpen(false)}
        footer={
          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              onClick={() => setEditorOpen(false)}
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={!canSubmit}
              className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
              onClick={() => void submit()}
            >
              Save
            </button>
          </div>
        }
      >
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Name</div>
            <input
              value={formName}
              onChange={(e) => setFormName(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="Amazon"
            />
            {!formName.trim() ? (
              <div className="mt-1 text-xs text-orange-600">Name is required.</div>
            ) : null}
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Slug (optional)</div>
            <input
              value={formSlug}
              onChange={(e) => setFormSlug(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="amazon"
            />
            <div className="mt-1 text-xs text-slate-500">Leave blank to auto-generate from the name.</div>
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Logo URL (direct HTTPS image)</div>
            <input
              value={formLogoUrl}
              onChange={(e) => setFormLogoUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="https://..."
              title="Logo URL must be a direct image link (.png/.jpg/.jpeg/.webp/.svg)"
            />
            <div className="mt-1 text-xs text-slate-500">
              Paste a direct image URL ending in .png/.jpg/.jpeg/.webp/.svg.
              Google Images links and website URLs (like https://www.shopsy.in) won’t render as logos.
            </div>
            {!logoValidation.ok ? (
              <div className="mt-1 text-xs text-orange-600">{logoValidation.reason}</div>
            ) : null}
          </label>

          <div className="md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Logo preview</div>
            <div className="flex items-center gap-3">
              <div className="h-16 w-16 overflow-hidden rounded-xl border border-slate-200 bg-white">
                <SafeImage
                  src={logoValidation.ok && formLogoUrl.trim() ? formLogoUrl.trim() : null}
                  alt={formName || 'Store logo'}
                  className="h-full w-full bg-slate-100 p-2"
                  imgClassName="h-full w-full object-contain"
                  fallbackClassName="flex h-full w-full items-center justify-center bg-slate-100 text-slate-300"
                />
              </div>
              <div className="text-xs text-slate-500">Fixed square preview with object-contain.</div>
            </div>
          </div>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Affiliate base URL</div>
            <input
              value={formAffiliateBaseUrl}
              onChange={(e) => setFormAffiliateBaseUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="https://affiliate.example.com"
            />
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Cashback rate</div>
            <input
              value={formCashbackRate}
              onChange={(e) => setFormCashbackRate(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder={formCashbackType === 'percentage' ? '5' : '150'}
            />
            {!cashbackRateValidation.ok ? (
              <div className="mt-1 text-xs text-orange-600">{cashbackRateValidation.reason}</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Cashback type</div>
            <select
              value={formCashbackType}
              onChange={(e) => setFormCashbackType(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              <option value="percentage">percentage</option>
              <option value="flat">flat</option>
            </select>
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Popularity score</div>
            <input
              value={formPopularityScore}
              onChange={(e) => setFormPopularityScore(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="0"
              inputMode="numeric"
            />
            {!popularityValidation.ok ? (
              <div className="mt-1 text-xs text-orange-600">{popularityValidation.reason}</div>
            ) : null}
          </label>

          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={formFeaturedStore}
              onChange={(e) => setFormFeaturedStore(e.target.checked)}
              className="h-4 w-4 rounded border-slate-300"
            />
            <div className="text-sm font-medium text-slate-700">Featured store</div>
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Category</div>
            <select
              value={formCategory}
              onChange={(e) => setFormCategory(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              {STORE_CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </label>

          <label className="flex items-center gap-2 md:col-span-2">
            <input
              type="checkbox"
              checked={formIsActive}
              onChange={(e) => setFormIsActive(e.target.checked)}
              className="h-4 w-4 rounded border-slate-300"
            />
            <div className="text-sm font-medium text-slate-700">Active</div>
          </label>
        </div>

      </Modal>
    </div>
  )
}
