export type DirectImageUrlValidation = {
  ok: boolean
  normalized?: string
  reason?: string
}

const IMAGE_EXT_RE = /\.(png|jpe?g|webp|svg)$/i

export function validateDirectImageUrl(
  raw: string,
  options?: {
    requireHttps?: boolean
  },
): DirectImageUrlValidation {
  const requireHttps = options?.requireHttps ?? true
  const trimmed = (raw ?? '').trim()
  if (!trimmed) return { ok: false, reason: 'Image URL is required' }

  let url: URL
  try {
    url = new URL(trimmed)
  } catch {
    return { ok: false, reason: 'Invalid URL format' }
  }

  if (requireHttps && url.protocol !== 'https:') {
    return { ok: false, reason: 'Must start with https://' }
  }

  const pathname = url.pathname || ''
  if (!IMAGE_EXT_RE.test(pathname)) {
    return {
      ok: false,
      reason: 'Must be a direct image link ending in .png/.jpg/.jpeg/.webp/.svg',
    }
  }

  // Common non-direct-image patterns (kept minimal; extension check is the main rule).
  const host = (url.hostname || '').toLowerCase()
  const path = pathname.toLowerCase()
  if (host.includes('google.') && (path.includes('/imgres') || url.searchParams.has('imgurl'))) {
    return { ok: false, reason: 'Google Images links are not direct image URLs' }
  }

  return { ok: true, normalized: url.toString() }
}
