import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'

type ToastType = 'success' | 'error' | 'info'

type Toast = {
  id: string
  type: ToastType
  message: string
}

type ToastContextValue = {
  push: (type: ToastType, message: string) => void
  success: (message: string) => void
  error: (message: string) => void
  info: (message: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

function cls(type: ToastType) {
  if (type === 'success') return 'border-blue-600 bg-white text-slate-900'
  if (type === 'error') return 'border-orange-600 bg-orange-50 text-slate-900'
  return 'border-slate-200 bg-white text-slate-900'
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const mountedRef = useRef(true)
  const timeoutByToastIdRef = useRef<Record<string, number>>({})

  useEffect(() => {
    return () => {
      mountedRef.current = false
      for (const id of Object.values(timeoutByToastIdRef.current)) {
        window.clearTimeout(id)
      }
      timeoutByToastIdRef.current = {}
    }
  }, [])

  const dismiss = useCallback((id: string) => {
    const timeoutId = timeoutByToastIdRef.current[id]
    if (timeoutId) {
      window.clearTimeout(timeoutId)
      delete timeoutByToastIdRef.current[id]
    }
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const push = useCallback((type: ToastType, message: string) => {
    const id = `${Date.now()}_${Math.random().toString(16).slice(2)}`
    setToasts((prev) => [...prev, { id, type, message }])
    const timeoutId = window.setTimeout(() => {
      if (!mountedRef.current) return
      dismiss(id)
    }, 4500)
    timeoutByToastIdRef.current[id] = timeoutId
  }, [dismiss])

  const value = useMemo<ToastContextValue>(
    () => ({
      push,
      success: (m) => push('success', m),
      error: (m) => push('error', m),
      info: (m) => push('info', m),
    }),
    [push],
  )

  return (
    <ToastContext.Provider value={value}>
      {children}

      <div className="fixed right-4 top-4 z-50 flex w-full max-w-sm flex-col gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={
              'flex items-start justify-between gap-3 rounded-xl border px-4 py-3 text-sm shadow-sm ' +
              cls(t.type)
            }
          >
            <div className="min-w-0 flex-1 break-words">{t.message}</div>
            <button
              type="button"
              className="shrink-0 rounded-lg border border-slate-200 bg-white px-2 py-1 text-xs font-semibold text-slate-600 hover:bg-slate-50"
              onClick={() => dismiss(t.id)}
              aria-label="Dismiss notification"
              title="Dismiss"
            >
              Close
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}
