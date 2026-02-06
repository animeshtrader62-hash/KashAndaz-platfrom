import { useCallback, useEffect, useMemo, useState } from 'react'
import { adminApi } from '../api/admin'
import type { BannerCreate, BannerOut, BannerUpdate, OfferOut } from '../api/types'
import { ApiError } from '../api/errors'
import { API_BASE_URL } from '../api/config'
import { useAuth } from '../auth/AuthContext'
import { Modal } from '../components/Modal'
import { SafeImage } from '../components/SafeImage'
import { SkeletonTable } from '../components/SkeletonTable'
import { StatusBadge } from '../components/StatusBadge'
import { Table } from '../components/Table'
import { useToast } from '../components/ToastProvider'
import { fromIsoToDateTimeLocal, formatDateShort, toIsoFromDateTimeLocal } from '../utils/date'
import { validateDirectImageUrl } from '../utils/imageUrl'

type BannerEditorMode = 'create' | 'edit'

export function BannersPage() {
  const { token, handleApiError } = useAuth()
  const toast = useToast()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [offers, setOffers] = useState<OfferOut[]>([])
  const [banners, setBanners] = useState<BannerOut[]>([])

  const [filterOfferId, setFilterOfferId] = useState<string>('')
  const [filterStatus, setFilterStatus] = useState<string>('')

  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<BannerEditorMode>('create')
  const [editingBanner, setEditingBanner] = useState<BannerOut | null>(null)

  const [formOfferId, setFormOfferId] = useState('')
  const [formImageUrl, setFormImageUrl] = useState('')
  const [uploadFile, setUploadFile] = useState<File | null>(null)
  const [uploadPreviewUrl, setUploadPreviewUrl] = useState<string | null>(null)
  const [previewLoadFailed, setPreviewLoadFailed] = useState(false)
  const [formPriority, setFormPriority] = useState(100)
  const [formStartAt, setFormStartAt] = useState('')
  const [formEndAt, setFormEndAt] = useState('')
  const [formStatus, setFormStatus] = useState<'active' | 'inactive'>('inactive')

  const activeOffers = useMemo(
    () => offers.filter((o) => String(o.status).toLowerCase() === 'active'),
    [offers],
  )

  const imageUrlValidation = useMemo(() => {
    if (!formImageUrl.trim()) return { ok: false, reason: 'Image URL is required' } as const
    return validateDirectImageUrl(formImageUrl, { requireHttps: true })
  }, [formImageUrl])

  const offerById = useMemo(() => {
    const m = new Map<string, OfferOut>()
    for (const o of offers) m.set(o.id, o)
    return m
  }, [offers])

  const bannersQuery = useMemo(() => {
    return {
      page: 1,
      limit: 20,
      offer_id: filterOfferId || undefined,
      status: filterStatus || undefined,
    }
  }, [filterOfferId, filterStatus])

  const canSubmit = useMemo(() => {
    if (editorMode === 'create' && !formOfferId) return false
    // For create: require offer.
    if (editorMode === 'create' && activeOffers.length === 0) return false
    // Phase-2: Uploads are preview-only. A valid direct image URL is required to save.
    if (!imageUrlValidation.ok) return false
    if (!formStartAt || !formEndAt) return false
    const start = new Date(formStartAt).getTime()
    const end = new Date(formEndAt).getTime()
    if (!Number.isFinite(start) || !Number.isFinite(end)) return false
    if (start >= end) return false

    if (!Number.isFinite(Number(formPriority))) return false
    const p = Math.trunc(Number(formPriority))
    if (p < 1 || p > 100) return false

    if (formStatus === 'active') {
      const o = offerById.get(formOfferId)
      if (o && o.status !== 'active') return false
    }
    return true
  }, [activeOffers.length, editorMode, formEndAt, formOfferId, formPriority, formStartAt, formStatus, imageUrlValidation.ok, offerById])

  const resetForm = useCallback(() => {
    setFormOfferId('')
    setFormImageUrl('')
    setUploadFile(null)
    setUploadPreviewUrl((prev) => {
      if (prev) URL.revokeObjectURL(prev)
      return null
    })
    setPreviewLoadFailed(false)
    setFormPriority(100)
    setFormStartAt('')
    setFormEndAt('')
    setFormStatus('inactive')
  }, [])

  const openCreate = useCallback(() => {
    setEditorMode('create')
    setEditingBanner(null)
    resetForm()
    setEditorOpen(true)
  }, [resetForm])

  const openEdit = useCallback(
    (b: BannerOut) => {
      setEditorMode('edit')
      setEditingBanner(b)
      setFormOfferId(b.offer_id)
      setFormImageUrl(b.image_url)
      setUploadFile(null)
      setUploadPreviewUrl((prev) => {
        if (prev) URL.revokeObjectURL(prev)
        return null
      })
      setPreviewLoadFailed(false)
      setFormPriority(b.priority)
      setFormStartAt(fromIsoToDateTimeLocal(b.start_at))
      setFormEndAt(fromIsoToDateTimeLocal(b.end_at))
      setFormStatus(b.status)
      setEditorOpen(true)
    },
    [],
  )

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const [offersRes, bannersRes] = await Promise.all([
        adminApi.listOffers(token, { page: 1, limit: 100 }),
        adminApi.listBanners(token, bannersQuery),
      ])
      setOffers(offersRes.offers)
      setBanners(bannersRes.banners)
    } catch (err) {
      handleApiError(err)
      setError(err instanceof ApiError ? err.message : 'Failed to load banners')
    } finally {
      setLoading(false)
    }
  }, [bannersQuery, handleApiError, token])

  useEffect(() => {
    void load()
  }, [load])

  const submit = useCallback(async () => {
    if (!token) return
    try {
      const start_at = toIsoFromDateTimeLocal(formStartAt)
      const end_at = toIsoFromDateTimeLocal(formEndAt)

      const directImage = validateDirectImageUrl(formImageUrl, { requireHttps: true })
      if (!directImage.ok) {
        toast.error(directImage.reason ?? 'Invalid image_url')
        return
      }
      if (new Date(start_at).getTime() >= new Date(end_at).getTime()) {
        toast.error('start_at must be before end_at')
        return
      }

      const p = Math.trunc(Number(formPriority))
      if (!Number.isFinite(p) || p < 1 || p > 100) {
        toast.error('priority must be between 1 and 100')
        return
      }

      const offer = offerById.get(formOfferId)
      if (formStatus === 'active' && offer && offer.status !== 'active') {
        toast.error('Banner cannot be active if offer is inactive')
        return
      }

      if (editorMode === 'create' && !formOfferId) {
        toast.error('Select an offer')
        return
      }

      if (editorMode === 'create') {
        const payload: BannerCreate = {
          offer_id: formOfferId,
          // Phase-2: backend stores only URL. Upload is preview-only.
          image_url: directImage.normalized ?? formImageUrl.trim(),
          priority: p,
          start_at,
          end_at,
          status: formStatus,
        }
        await adminApi.createBanner(token, payload)
        toast.success('Banner created')
      } else {
        if (!editingBanner) return
        const payload: BannerUpdate = {
          image_url: directImage.normalized ?? formImageUrl.trim(),
          priority: p,
          start_at,
          end_at,
          status: formStatus,
        }
        await adminApi.updateBanner(token, editingBanner.id, payload)
        toast.success('Banner updated')
      }

      setEditorOpen(false)
      await load()
    } catch (err) {
      handleApiError(err)
      toast.error(err instanceof ApiError ? err.message : 'Save failed')
    }
  }, [
    editorMode,
    editingBanner,
    formEndAt,
    formImageUrl,
    formOfferId,
    formPriority,
    formStartAt,
    formStatus,
    handleApiError,
    load,
    offerById,
    toast,
    token,
  ])

  const selectedOffer = useMemo(() => {
    if (!formOfferId) return null
    return offerById.get(formOfferId) ?? null
  }, [formOfferId, offerById])

  const previewSrc = useMemo(() => {
    const url = (uploadPreviewUrl ?? '').trim()
    if (url) return url
    const img = formImageUrl.trim()
    if (!img) return null
    const v = validateDirectImageUrl(img, { requireHttps: true })
    if (!v.ok) return null
    return v.normalized ?? img
  }, [formImageUrl, uploadPreviewUrl])

  const onSelectFile = useCallback(
    (file: File | null) => {
      if (!file) {
        setUploadFile(null)
        setUploadPreviewUrl(null)
        setPreviewLoadFailed(false)
        return
      }

      const allowed = ['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
      const maxBytes = 2 * 1024 * 1024
      if (!allowed.includes(file.type)) {
        toast.error('Only PNG, JPG, WEBP, or SVG files are allowed')
        return
      }
      if (file.size > maxBytes) {
        toast.error('Max file size is 2MB')
        return
      }

      setUploadFile(file)
      const objectUrl = URL.createObjectURL(file)
      setUploadPreviewUrl((prev) => {
        if (prev) URL.revokeObjectURL(prev)
        return objectUrl
      })
      setPreviewLoadFailed(false)
    },
    [toast],
  )

  const toggleStatus = useCallback(
    async (b: BannerOut) => {
      if (!token) return
      try {
        const offer = offerById.get(b.offer_id)
        const next = b.status === 'active' ? 'inactive' : 'active'
        if (next === 'active' && offer && offer.status !== 'active') {
          toast.error('Cannot activate banner when offer is inactive')
          return
        }
        const updated = await adminApi.setBannerStatus(token, b.id, next)
        setBanners((prev) => prev.map((x) => (x.id === b.id ? updated : x)))
      } catch (err) {
        handleApiError(err)
        toast.error(err instanceof ApiError ? err.message : 'Update failed')
      }
    },
    [handleApiError, offerById, toast, token],
  )

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Banners</h2>
          <p className="mt-1 text-sm text-slate-600">Manage promotional banners.</p>
          <div className="mt-1 text-xs text-slate-500">
            API: <span className="font-mono">{API_BASE_URL}</span> · query: page={bannersQuery.page}, limit={bannersQuery.limit}
          </div>
        </div>
        <button
          type="button"
          className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
          onClick={openCreate}
        >
          + Add Banner
        </button>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <label className="block">
          <div className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Offer
          </div>
          <select
            value={filterOfferId}
            onChange={(e) => setFilterOfferId(e.target.value)}
            className="w-72 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
          >
            <option value="">All offers</option>
            {offers.map((o) => (
              <option key={o.id} value={o.id}>
                {o.title} ({o.status})
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <div className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Status
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="w-40 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
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
        <div className="rounded-2xl border border-rose-200 bg-rose-50 p-5">
          <div className="text-sm font-semibold text-rose-900">Failed to load banners</div>
          <div className="mt-1 text-sm text-rose-800">{error}</div>
          <button
            type="button"
            className="mt-4 rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
            onClick={() => void load()}
          >
            Retry
          </button>
        </div>
      ) : banners.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <div className="text-sm font-semibold text-slate-900">No banners</div>
          <div className="mt-1 text-sm text-slate-600">Create a banner for an offer.</div>
        </div>
      ) : (
        <Table columns={['Offer', 'Image', 'Window', 'Priority', 'Status', 'Actions']}>
          {banners.map((b) => {
            const offer = offerById.get(b.offer_id)
            return (
              <tr key={b.id} className="hover:bg-slate-50">
                <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                  <div className="font-medium">{offer?.title ?? b.offer_id}</div>
                  <div className="mt-1 text-xs font-normal text-slate-500">
                    Offer status: {offer?.status ?? 'unknown'}
                  </div>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-16 overflow-hidden rounded-lg border border-slate-200 bg-slate-100">
                      <img
                        src={b.image_url}
                        alt={offer?.title ?? b.offer_id}
                        className="h-full w-full object-contain"
                        loading="lazy"
                      />
                    </div>
                    <div className="text-xs text-slate-600 break-all max-w-[480px]">{b.image_url}</div>
                  </div>
                </td>
                <td className="px-4 py-3 text-sm text-slate-700">
                  <div>{formatDateShort(b.start_at)}</div>
                  <div className="text-xs text-slate-500">→ {formatDateShort(b.end_at)}</div>
                </td>
                <td className="px-4 py-3 text-sm text-slate-700">{b.priority}</td>
                <td className="px-4 py-3 text-sm">
                  <StatusBadge active={b.status === 'active'} />
                </td>
                <td className="px-4 py-3 text-sm">
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                      onClick={() => openEdit(b)}
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      className={
                        'rounded-lg px-3 py-1.5 text-sm font-semibold ' +
                        (b.status === 'active'
                          ? 'border border-rose-200 bg-rose-50 text-rose-700 hover:bg-rose-100'
                          : 'border border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100')
                      }
                      onClick={() => void toggleStatus(b)}
                    >
                      {b.status === 'active' ? 'Deactivate' : 'Activate'}
                    </button>
                  </div>
                </td>
              </tr>
            )
          })}
        </Table>
      )}

      <Modal
        open={editorOpen}
        title={editorMode === 'create' ? 'Create banner' : 'Edit banner'}
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
              className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-60"
              onClick={() => void submit()}
            >
              Save
            </button>
          </div>
        }
      >
        <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4 text-sm text-slate-700">
          <div className="font-semibold text-slate-900">How banners work</div>
          <ul className="mt-1 space-y-1 text-sm text-slate-700">
            <li>Banner clicks redirect users to the linked offer.</li>
            <li>If a banner is inactive or out of its time window, it won’t appear in the app.</li>
            <li>
              <span className="inline-flex items-center gap-2">
                <span className="rounded-full bg-slate-900 px-2 py-0.5 text-xs font-semibold text-white">
                  Phase 2 (Live APIs, No Storage)
                </span>
                <span className="text-sm">Uploads are preview-only.</span>
              </span>
            </li>
          </ul>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Offer</div>
            <select
              value={formOfferId}
              disabled={editorMode === 'edit'}
              onChange={(e) => setFormOfferId(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400 disabled:bg-slate-50"
            >
              <option value="">Select an offer</option>
              {(editorMode === 'create' ? activeOffers : offers).map((o) => (
                <option key={o.id} value={o.id}>
                  {o.title} ({o.status})
                </option>
              ))}
            </select>
            {editorMode === 'create' && activeOffers.length === 0 ? (
              <div className="mt-1 text-xs text-rose-700">
                No offers found. Create an offer first to attach banners.
              </div>
            ) : editorMode === 'create' && !formOfferId ? (
              <div className="mt-1 text-xs text-rose-700">Select an active offer to continue.</div>
            ) : (
              <div className="mt-1 text-xs text-slate-500">Only active offers are selectable for new banners.</div>
            )}
          </label>

          {selectedOffer ? (
            <div className="md:col-span-2 rounded-2xl border border-slate-200 bg-white p-4">
              <div className="text-sm font-semibold text-slate-900">Click-through preview</div>
              <div className="mt-1 text-sm text-slate-700">
                Offer: <span className="font-medium">{selectedOffer.title}</span> ({selectedOffer.status})
              </div>
              <div className="mt-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Redirect URL
              </div>
              <div className="mt-1 text-xs text-slate-700 break-all">{selectedOffer.affiliate_redirect_url}</div>
              <div className="mt-2 text-xs text-slate-500">
                Tip: Ensure this is the final affiliate redirect URL (Offer18 automation can be added later).
              </div>
            </div>
          ) : null}

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Image URL (direct HTTPS image)</div>
            <input
              value={formImageUrl}
              onChange={(e) => setFormImageUrl(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              placeholder="https://..."
            />
            <div className="mt-1 text-xs text-slate-500">
              Paste a direct image URL ending in .png/.jpg/.jpeg/.webp/.svg.
              Google Images links, blog URLs, and website homepages will not work.
            </div>
            {uploadPreviewUrl ? (
              <div className="mt-1 text-xs text-slate-600">
                Upload is preview-only. Paste HTTPS image URL to save.
              </div>
            ) : null}
            {!uploadPreviewUrl && !imageUrlValidation.ok ? (
              <div className="mt-1 text-xs text-rose-700">{imageUrlValidation.reason}</div>
            ) : null}
          </label>

          <label className="block md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Image upload (optional, max 2MB)</div>
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp,image/svg+xml"
              className="block w-full text-sm text-slate-700 file:mr-4 file:rounded-xl file:border-0 file:bg-slate-900 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-white hover:file:bg-slate-800"
              onChange={(e) => onSelectFile(e.target.files?.[0] ?? null)}
            />
            {uploadFile ? (
              <div className="mt-1 text-xs text-slate-600">
                Selected: <span className="font-mono">{uploadFile.name}</span>
              </div>
            ) : null}
            <div className="mt-1 text-xs text-slate-500">
              Upload is preview-only. No server upload in Phase 2.
              Host the image somewhere and paste the HTTPS direct image URL to save.
            </div>
          </label>

          <div className="md:col-span-2">
            <div className="mb-1 text-sm font-semibold text-slate-700">Live preview</div>
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
              <div className="w-full">
                <div className="relative w-full overflow-hidden rounded-xl border border-slate-200 bg-slate-100 pt-[56.25%]">
                  <div className="absolute inset-0">
                    <SafeImage
                      src={previewSrc}
                      alt={selectedOffer?.title ?? 'Banner preview'}
                      className="h-full w-full"
                      imgClassName="h-full w-full object-contain"
                      fallbackClassName="flex h-full w-full items-center justify-center bg-slate-100 text-slate-300"
                      onLoad={() => setPreviewLoadFailed(false)}
                      onError={() => setPreviewLoadFailed(true)}
                    />
                  </div>
                </div>
                <div className="mt-1 text-xs text-slate-500">Preview is fixed 16:9 with object-contain.</div>
              </div>
              <div className="text-xs text-slate-600">
                <div className="font-semibold text-slate-700">Preview source</div>
                <div className="mt-1">{uploadPreviewUrl ? 'Uploaded file (preview only)' : 'Image URL'}</div>
                {previewSrc && previewLoadFailed ? (
                  <div className="mt-1 text-xs text-rose-700">Image failed to load. Check the URL.</div>
                ) : null}
                {uploadPreviewUrl ? (
                  <div className="mt-2 text-xs text-slate-500">If both upload + URL exist, the URL is what gets saved.</div>
                ) : null}
              </div>
            </div>
          </div>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Priority</div>
            <input
              type="number"
              value={formPriority}
              onChange={(e) => setFormPriority(Number(e.target.value))}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
              min={1}
              max={100}
            />
            <div className="mt-1 text-xs text-slate-500">1–100 (affects sorting only).</div>
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Status</div>
            <select
              value={formStatus}
              onChange={(e) => setFormStatus(e.target.value === 'active' ? 'active' : 'inactive')}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            >
              <option value="inactive">inactive</option>
              <option value="active">active</option>
            </select>
            {formStatus === 'active' && formOfferId && offerById.get(formOfferId)?.status !== 'active' ? (
              <div className="mt-1 text-xs text-rose-700">Offer must be active to activate banner.</div>
            ) : null}
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">Start at</div>
            <input
              type="datetime-local"
              value={formStartAt}
              onChange={(e) => setFormStartAt(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            />
          </label>

          <label className="block">
            <div className="mb-1 text-sm font-semibold text-slate-700">End at</div>
            <input
              type="datetime-local"
              value={formEndAt}
              onChange={(e) => setFormEndAt(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-slate-400"
            />
            {formStartAt && formEndAt && new Date(formStartAt).getTime() >= new Date(formEndAt).getTime() ? (
              <div className="mt-1 text-xs text-rose-700">start_at must be before end_at</div>
            ) : null}
          </label>
        </div>

      </Modal>
    </div>
  )
}
