import { useCallback, useEffect, useMemo, useState } from 'react'
import { adminApi } from '../api/admin'
import type { AdminStoreListItem, OfferCreate, OfferOut, OfferUpdate, OfferType } from '../api/types'
import { ApiError } from '../api/errors'
import { useAuth } from '../auth/AuthContext'
import { Modal } from '../components/Modal'
import { SafeImage } from '../components/SafeImage'
import { SkeletonTable } from '../components/SkeletonTable'
import { StatusBadge } from '../components/StatusBadge'
import { Table } from '../components/Table'
import { useToast } from '../components/ToastProvider'
import { fromIsoToDateTimeLocal, formatDateShort, toIsoFromDateTimeLocal } from '../utils/date'
import { validateDirectImageUrl } from '../utils/imageUrl'

type OfferEditorMode = 'create' | 'edit'

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

export function OffersPage() {
  const { token, handleApiError } = useAuth()
  const toast = useToast()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [stores, setStores] = useState<AdminStoreListItem[]>([])
  const [offers, setOffers] = useState<OfferOut[]>([])

  const [filterStoreId, setFilterStoreId] = useState<string>('')
  const [filterStatus, setFilterStatus] = useState<string>('')

  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<OfferEditorMode>('create')
  const [editingOffer, setEditingOffer] = useState<OfferOut | null>(null)

  const [formStoreId, setFormStoreId] = useState('')
  const [formTitle, setFormTitle] = useState('')
  const [formDescription, setFormDescription] = useState('')
  const [formAffiliateUrl, setFormAffiliateUrl] = useState('')
  const [formCashbackText, setFormCashbackText] = useState('')
  const [formOfferType, setFormOfferType] = useState<OfferType>('deal')
  const [formIsFeatured, setFormIsFeatured] = useState(false)
  const [formStartAt, setFormStartAt] = useState('')
  const [formEndAt, setFormEndAt] = useState('')
  const [formStatus, setFormStatus] = useState<'active' | 'inactive'>('inactive')

  const [storeCreatorOpen, setStoreCreatorOpen] = useState(false)
  const [storeFormName, setStoreFormName] = useState('')
  const [storeFormLogoUrl, setStoreFormLogoUrl] = useState('')
  const [storeFormAffiliateBaseUrl, setStoreFormAffiliateBaseUrl] = useState('')
  const [storeFormCashbackRate, setStoreFormCashbackRate] = useState('')
  const [storeFormCashbackType, setStoreFormCashbackType] = useState('percentage')
  const [storeFormCategory, setStoreFormCategory] = useState('')
  const [storeFormIsActive, setStoreFormIsActive] = useState(true)

  const storeLogoValidation = useMemo(() => {
    const v = storeFormLogoUrl.trim()
    if (!v) return { ok: false, reason: 'Logo URL is required.' } as const
    return validateDirectImageUrl(v, { requireHttps: true })
  }, [storeFormLogoUrl])

  const storeCashbackRateValidation = useMemo(() => {
    const v = storeFormCashbackRate.trim()
    if (!v) return { ok: false, reason: 'Cashback rate is required.' } as const
    if (v.includes('%')) return { ok: false, reason: 'Enter a number only (do not include %).' } as const
    const n = Number(v)
    if (!Number.isFinite(n)) return { ok: false, reason: 'Cashback rate must be a valid number.' } as const
    if (n < 0) return { ok: false, reason: 'Cashback rate must be >= 0.' } as const
    if (storeFormCashbackType === 'percentage' && n > 100)
      return { ok: false, reason: 'Percentage cashback rate must be <= 100.' } as const
    return { ok: true } as const
  }, [storeFormCashbackRate, storeFormCashbackType])

  const storeNameById = useMemo(() => {
    const m = new Map<string, string>()
    for (const s of stores) m.set(s.id, s.name)
    return m
  }, [stores])

  const activeStores = useMemo(() => stores.filter((s) => s.is_active), [stores])

  const canSubmit = useMemo(() => {
    if (editorMode === 'create' && !formStoreId) return false
    if (!formTitle.trim()) return false
    if (!formAffiliateUrl.trim()) return false
    if (!formAffiliateUrl.trim().startsWith('https://')) return false
    if (!formCashbackText.trim()) return false
    if (!formStartAt || !formEndAt) return false
    const start = new Date(formStartAt).getTime()
    const end = new Date(formEndAt).getTime()
    if (!Number.isFinite(start) || !Number.isFinite(end)) return false
    if (start >= end) return false
    return true
  }, [
    editorMode,
    formAffiliateUrl,
    formCashbackText,
    formEndAt,
    formStartAt,
    formStoreId,
    formTitle,
  ])

  const canCreateStore = useMemo(() => {
    if (!storeFormName.trim()) return false
    if (!storeCashbackRateValidation.ok) return false
    if (!storeFormCashbackType.trim()) return false
    if (!storeLogoValidation.ok) return false
    if (storeFormAffiliateBaseUrl.trim() && !storeFormAffiliateBaseUrl.trim().startsWith('https://')) return false
    return true
  }, [
    storeFormAffiliateBaseUrl,
    storeCashbackRateValidation.ok,
    storeFormCashbackType,
    storeFormName,
    storeLogoValidation.ok,
  ])

  const resetForm = useCallback(() => {
    setFormStoreId('')
    setFormTitle('')
    setFormDescription('')
    setFormAffiliateUrl('')
    setFormCashbackText('')
    setFormOfferType('deal')
    setFormIsFeatured(false)
    setFormStartAt('')
    setFormEndAt('')
    setFormStatus('inactive')
  }, [])

  const resetStoreForm = useCallback(() => {
    setStoreFormName('')
    setStoreFormLogoUrl('')
    setStoreFormAffiliateBaseUrl('')
    setStoreFormCashbackRate('')
    setStoreFormCashbackType('percentage')
    setStoreFormCategory('')
    setStoreFormIsActive(true)
  }, [])

  const openCreate = useCallback(() => {
    setEditorMode('create')
    setEditingOffer(null)
    resetForm()
    setEditorOpen(true)
  }, [resetForm])

  const openCreateStore = useCallback(() => {
    resetStoreForm()
    setStoreCreatorOpen(true)
  }, [resetStoreForm])

  const openEdit = useCallback((o: OfferOut) => {
    setEditorMode('edit')
    setEditingOffer(o)
    setFormStoreId(o.store_id)
    setFormTitle(o.title)
    setFormDescription(o.description ?? '')
    setFormAffiliateUrl(o.affiliate_redirect_url)
    setFormCashbackText(o.cashback_text)
    setFormOfferType(o.offer_type)
    setFormIsFeatured(!!o.is_featured)
    setFormStartAt(fromIsoToDateTimeLocal(o.start_at))
    setFormEndAt(fromIsoToDateTimeLocal(o.end_at))
    setFormStatus(o.status)
    setEditorOpen(true)
  }, [])

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const [storesRes, offersRes] = await Promise.all([
        adminApi.listStores(token, 1, 50),
        adminApi.listOffers(token, {
          store_id: filterStoreId || undefined,
          status: filterStatus || undefined,
          page: 1,
          limit: 50,
        }),
      ])
      setStores(storesRes.stores)
      setOffers(offersRes.offers)
    } catch (err) {
      handleApiError(err)
      setError(err instanceof ApiError ? err.message : 'Failed to load offers')
    } finally {
      setLoading(false)
    }
  }, [filterStatus, filterStoreId, handleApiError, token])

  const submitStore = useCallback(async () => {
    if (!token) return
    try {
      const payload = {
        name: storeFormName.trim(),
        logo_url: storeFormLogoUrl.trim(),
        affiliate_base_url: storeFormAffiliateBaseUrl.trim() ? storeFormAffiliateBaseUrl.trim() : null,
        cashback_rate: storeFormCashbackRate.trim(),
        cashback_type: storeFormCashbackType.trim(),
        category: storeFormCategory.trim() ? storeFormCategory.trim() : null,
        is_active: storeFormIsActive,
      }

      const created = await adminApi.createStore(token, payload)
      toast.success('Store created')

      // Refresh store list and preselect newly created store for the offer.
      const storesRes = await adminApi.listStores(token, 1, 50)
      setStores(storesRes.stores)
      setFormStoreId(created.id)

      setStoreCreatorOpen(false)
    } catch (err) {
      handleApiError(err)
      toast.error(err instanceof ApiError ? err.message : 'Failed to create store')
    }
  }, [
    handleApiError,
    storeFormAffiliateBaseUrl,
    storeFormCashbackRate,
    storeFormCashbackType,
    storeFormCategory,
    storeFormIsActive,
    storeFormLogoUrl,
    storeFormName,
    toast,
    token,
  ])

  useEffect(() => {
    void load()
  }, [load])

  const submit = useCallback(async () => {
    if (!token) return
    try {
      const start_at = toIsoFromDateTimeLocal(formStartAt)
      const end_at = toIsoFromDateTimeLocal(formEndAt)
      if (new Date(start_at).getTime() >= new Date(end_at).getTime()) {
        toast.error('start_at must be before end_at')
        return
      }
      if (!formAffiliateUrl.trim().startsWith('https://')) {
        toast.error('affiliate_redirect_url must be HTTPS')
        return
      }

      if (editorMode === 'create') {
        const payload: OfferCreate = {
          store_id: formStoreId,
          title: formTitle.trim(),
          description: formDescription.trim() ? formDescription.trim() : null,
          affiliate_redirect_url: formAffiliateUrl.trim(),
          cashback_text: formCashbackText.trim(),
          offer_type: formOfferType,
          is_featured: formIsFeatured,
          start_at,
          end_at,
          status: formStatus,
        }
        await adminApi.createOffer(token, payload)
        toast.success('Offer created')
      } else {
        if (!editingOffer) return
        const payload: OfferUpdate = {
          title: formTitle.trim(),
          description: formDescription.trim() ? formDescription.trim() : null,
          affiliate_redirect_url: formAffiliateUrl.trim(),
          cashback_text: formCashbackText.trim(),
          offer_type: formOfferType,
          is_featured: formIsFeatured,
          start_at,
          end_at,
          status: formStatus,
        }
        await adminApi.updateOffer(token, editingOffer.id, payload)
        toast.success('Offer updated')
      }

      setEditorOpen(false)
      await load()
    } catch (err) {
      handleApiError(err)
      toast.error(err instanceof ApiError ? err.message : 'Save failed')
    }
  }, [
    editorMode,
    editingOffer,
    formAffiliateUrl,
    formCashbackText,
    formDescription,
    formEndAt,
    formIsFeatured,
    formOfferType,
    formStartAt,
    formStatus,
    formStoreId,
    formTitle,
    handleApiError,
    load,
    toast,
    token,
  ])

  const toggleStatus = useCallback(
    async (o: OfferOut) => {
      if (!token) return
      try {
        const next = o.status === 'active' ? 'inactive' : 'active'
        const updated = await adminApi.setOfferStatus(token, o.id, next)
        setOffers((prev) => prev.map((x) => (x.id === o.id ? updated : x)))
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
          <h2 className="text-xl font-bold text-slate-900">Offers</h2>
          <p className="mt-1 text-sm text-slate-600">Manage campaigns/sales per store.</p>
        </div>
        <button
          type="button"
          className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
          onClick={openCreate}
        >
          + Add Offer
        </button>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <label className="block">
          <div className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">Store</div>
          <select
            value={filterStoreId}
            onChange={(e) => setFilterStoreId(e.target.value)}
            className="w-64 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
          >
            <option value="">All stores</option>
            {stores.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <div className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">Status</div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="w-40 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
          >
            <option value="">All</option>
            <option value="active">active</option>
            <option value="inactive">inactive</option>
          </select>
        </label>

        <button
          type="button"
          className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          onClick={() => void load()}
        >
          Refresh
        </button>
      </div>

      {loading ? (
        <SkeletonTable rows={8} cols={5} />
      ) : error ? (
        <div className="rounded-2xl border border-orange-600 bg-orange-50 p-5">
          <div className="text-sm font-semibold text-slate-900">Failed to load offers</div>
          <div className="mt-1 text-sm text-slate-700">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            onClick={() => void load()}
          >
            Retry
          </button>
        </div>
      ) : offers.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No offers</div>
          <div className="mt-1 text-sm text-slate-600">Create an offer to start promoting a store.</div>
        </div>
      ) : (
        <Table columns={['Store', 'Title', 'Window', 'Status', 'Actions']}>
          {offers.map((o) => (
            <tr key={o.id} className="hover:bg-slate-50">
              <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                {storeNameById.get(o.store_id) ?? o.store_id}
              </td>
              <td className="px-4 py-3 text-sm text-slate-700">
                <div className="font-medium text-slate-900">{o.title}</div>
                <div className="mt-1 text-xs text-slate-500 break-all">{o.affiliate_redirect_url}</div>
              </td>
              <td className="px-4 py-3 text-sm text-slate-700">
                <div>{formatDateShort(o.start_at)}</div>
                <div className="text-xs text-slate-500">→ {formatDateShort(o.end_at)}</div>
              </td>
              <td className="px-4 py-3 text-sm">
                <StatusBadge active={o.status === 'active'} />
              </td>
              <td className="px-4 py-3 text-sm">
                <div className="flex flex-wrap gap-2">
                  <button
                    type="button"
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                    onClick={() => openEdit(o)}
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    className={
                      'rounded-lg px-3 py-1.5 text-sm font-semibold ' +
                      (o.status === 'active'
                        ? 'border border-orange-600 bg-orange-50 text-orange-600 hover:bg-orange-50'
                        : 'border border-blue-600 bg-white text-blue-600 hover:bg-slate-50')
                    }
                    onClick={() => void toggleStatus(o)}
                  >
                    {o.status === 'active' ? 'Deactivate' : 'Activate'}
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </Table>
      )}

      <Modal
        open={editorOpen}
        title={editorMode === 'create' ? 'Create offer' : 'Edit offer'}
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
            <div className="mb-1 flex items-center justify-between gap-3">
              <div className="text-sm font-semibold text-slate-700">Store</div>
              {editorMode === 'create' ? (
                <button
                  type="button"
                  className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                  onClick={openCreateStore}
                >
                  + New store
                </button>
              ) : null}
            </div>
            <select
              value={formStoreId}
              disabled={editorMode === 'edit'}
              onChange={(e) => setFormStoreId(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600 disabled:bg-slate-50"
            >
              <option value="">Select a store</option>
              {activeStores.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
            <div className="mt-1 text-xs text-slate-500">
              Only active stores can have new offers. If the platform isn’t listed yet, create it here.
            </div>
            {editorMode === 'create' && !formStoreId ? (
              <div className="mt-1 text-xs text-orange-600">Store is required.</div>
            ) : null}
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Title</div>
            <input
              value={formTitle}
              onChange={(e) => setFormTitle(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="Prime Day Deals"
            />
            <div className="mt-1 text-xs text-slate-500">
              Use a clear platform/campaign name.
            </div>
            {!formTitle.trim() ? (
              <div className="mt-1 text-xs text-orange-600">Title is required.</div>
            ) : null}
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Description</div>
            <textarea
              value={formDescription}
              onChange={(e) => setFormDescription(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="Optional"
              rows={3}
            />
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Affiliate redirect URL (HTTPS)</div>
            <input
              value={formAffiliateUrl}
              onChange={(e) => setFormAffiliateUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="https://..."
            />
            <div className="mt-1 text-xs text-slate-500">
              Paste the final affiliate link you want users to be redirected to.
            </div>
            {formAffiliateUrl.trim() && !formAffiliateUrl.trim().startsWith('https://') ? (
              <div className="mt-1 text-xs text-orange-600">Must start with https://</div>
            ) : null}
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Cashback text</div>
            <input
              value={formCashbackText}
              onChange={(e) => setFormCashbackText(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
              placeholder="Up to 5%"
            />
            {!formCashbackText.trim() ? (
              <div className="mt-1 text-xs text-orange-600">Cashback text is required.</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Offer type</div>
            <select
              value={formOfferType}
              onChange={(e) => setFormOfferType(e.target.value as OfferType)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
            >
              <option value="deal">deal</option>
              <option value="coupon">coupon</option>
              <option value="bank_offer">bank_offer</option>
              <option value="new_user">new_user</option>
            </select>
          </label>

          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={formIsFeatured}
              onChange={(e) => setFormIsFeatured(e.target.checked)}
              className="h-4 w-4 rounded border-slate-300"
            />
            <div className="text-sm font-medium text-slate-700">Featured</div>
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Start at</div>
            <input
              type="datetime-local"
              value={formStartAt}
              onChange={(e) => setFormStartAt(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
            />
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">End at</div>
            <input
              type="datetime-local"
              value={formEndAt}
              onChange={(e) => setFormEndAt(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
            />
            {formStartAt && formEndAt && new Date(formStartAt).getTime() >= new Date(formEndAt).getTime() ? (
              <div className="mt-1 text-xs text-orange-600">start_at must be before end_at</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Status</div>
            <select
              value={formStatus}
              onChange={(e) => setFormStatus(e.target.value === 'active' ? 'active' : 'inactive')}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-blue-600"
            >
              <option value="inactive">inactive</option>
              <option value="active">active</option>
            </select>
          </label>
        </div>

      </Modal>

      <Modal
        open={storeCreatorOpen}
        title="Create store"
        onClose={() => setStoreCreatorOpen(false)}
        footer={
          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              onClick={() => setStoreCreatorOpen(false)}
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={!canCreateStore}
              className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
              onClick={() => void submitStore()}
            >
              Create
            </button>
          </div>
        }
      >
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Name</div>
            <input
              value={storeFormName}
              onChange={(e) => setStoreFormName(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="Shopsy"
            />
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Logo URL (direct HTTPS image)</div>
            <input
              value={storeFormLogoUrl}
              onChange={(e) => setStoreFormLogoUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="https://..."
              title="Logo URL must be a direct image link (.png/.jpg/.jpeg/.webp/.svg)"
            />
            <div className="mt-1 text-xs text-slate-500">
              Paste a direct image URL ending in .png/.jpg/.jpeg/.webp/.svg.
              Website URLs and Google Images links will not work.
            </div>
            {!storeLogoValidation.ok ? (
              <div className="mt-1 text-xs text-orange-600">{storeLogoValidation.reason}</div>
            ) : null}
          </label>

          <div className="md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Logo preview</div>
            <div className="flex items-center gap-3">
              <div className="h-16 w-16 overflow-hidden rounded-xl border border-slate-200 bg-white">
                <SafeImage
                  src={storeLogoValidation.ok && storeFormLogoUrl.trim() ? storeFormLogoUrl.trim() : null}
                  alt={storeFormName || 'Store logo'}
                  className="h-full w-full bg-slate-100 p-2"
                  imgClassName="h-full w-full object-contain"
                  fallbackClassName="flex h-full w-full items-center justify-center bg-slate-100 text-slate-300"
                />
              </div>
              <div className="text-xs text-slate-500">Fixed square preview with object-contain.</div>
            </div>
          </div>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Affiliate base URL (optional, HTTPS)</div>
            <input
              value={storeFormAffiliateBaseUrl}
              onChange={(e) => setStoreFormAffiliateBaseUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="https://..."
            />
            {storeFormAffiliateBaseUrl.trim() && !storeFormAffiliateBaseUrl.trim().startsWith('https://') ? (
              <div className="mt-1 text-xs text-orange-600">Must start with https://</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Cashback rate</div>
            <input
              value={storeFormCashbackRate}
              onChange={(e) => setStoreFormCashbackRate(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="5"
            />
            {!storeCashbackRateValidation.ok ? (
              <div className="mt-1 text-xs text-orange-600">{storeCashbackRateValidation.reason}</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Cashback type</div>
            <select
              value={storeFormCashbackType}
              onChange={(e) => setStoreFormCashbackType(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              <option value="percentage">percentage</option>
              <option value="flat">flat</option>
            </select>
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Category (optional)</div>
            <select
              value={storeFormCategory}
              onChange={(e) => setStoreFormCategory(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              {STORE_CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Status</div>
            <select
              value={storeFormIsActive ? 'active' : 'inactive'}
              onChange={(e) => setStoreFormIsActive(e.target.value === 'active')}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              <option value="active">active</option>
              <option value="inactive">inactive</option>
            </select>
          </label>
        </div>

      </Modal>
    </div>
  )
}
