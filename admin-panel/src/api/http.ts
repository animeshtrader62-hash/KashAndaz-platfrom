import { ApiError } from './errors'

type RequestOptions = {
  token?: string | null
  timeoutMs?: number
}

async function parseErrorBody(res: Response): Promise<{ message: string; body?: unknown }> {
  const contentType = res.headers.get('content-type') || ''

  try {
    if (contentType.includes('application/json')) {
      const body: unknown = await res.json()

      // FastAPI/Pydantic validation errors typically look like:
      // {"detail": [{"loc": ["body","email"], "msg": "field required", ...}, ...]}
      const detail = (body as { detail?: unknown })?.detail
      if (Array.isArray(detail)) {
        const msgs = detail
          .map((item) => {
            if (typeof item === 'string') return item
            if (typeof item === 'object' && item !== null) {
              const msg = (item as { msg?: unknown }).msg
              if (typeof msg === 'string' && msg.trim()) return msg
            }
            return null
          })
          .filter((m): m is string => Boolean(m))

        if (msgs.length) {
          return { message: msgs.join('; '), body }
        }
      }

      const message =
        (typeof (body as { detail?: unknown })?.detail === 'string' &&
          (body as { detail: string }).detail) ||
        (typeof (body as { message?: unknown })?.message === 'string' &&
          (body as { message: string }).message) ||
        res.statusText ||
        `HTTP ${res.status}`
      return { message, body }
    }

    const text = await res.text()
    return { message: text || res.statusText || `HTTP ${res.status}`, body: text }
  } catch {
    return { message: res.statusText || `HTTP ${res.status}` }
  }
}

export async function httpRequest<T = unknown>(
  url: string,
  init: RequestInit = {},
  options: RequestOptions = {},
): Promise<T> {
  const controller = new AbortController()
  const timeout = options.timeoutMs ?? 20000
  const id = window.setTimeout(() => controller.abort(), timeout)

  try {
    const headers = new Headers(init.headers)
    if (!headers.has('Content-Type') && init.body) {
      headers.set('Content-Type', 'application/json')
    }
    if (options.token) {
      headers.set('Authorization', `Bearer ${options.token}`)
    }

    const res = await fetch(url, {
      ...init,
      headers,
      signal: controller.signal,
    })

    if (!res.ok) {
      const { message, body } = await parseErrorBody(res)
      throw new ApiError(res.status, message, body)
    }

    if (res.status === 204) {
      return null as T
    }

    const contentType = res.headers.get('content-type') || ''
    if (contentType.includes('application/json')) {
      return (await res.json()) as T
    }

    return (await res.text()) as T
  } catch (err: unknown) {
    const maybeName =
      typeof err === 'object' && err !== null ? (err as { name?: unknown }).name : undefined
    if (maybeName === 'AbortError') {
      throw new ApiError(0, `Request timed out (${url})`, { url })
    }
    if (err instanceof ApiError) throw err

    const underlying =
      err instanceof Error
        ? err.message
        : typeof err === 'string'
          ? err
          : 'Failed to fetch'

    throw new ApiError(0, `Network error (${url}): ${underlying}`, { url, underlying })
  } finally {
    window.clearTimeout(id)
  }
}

export function jsonBody(value: unknown): string {
  return JSON.stringify(value)
}
