export function toIsoFromDateTimeLocal(value: string): string {
  // value expected like: 2026-01-30T10:15
  const d = new Date(value)
  return d.toISOString()
}

export function fromIsoToDateTimeLocal(iso: string): string {
  const d = new Date(iso)
  // Convert to local datetime-local input format: YYYY-MM-DDTHH:mm
  const pad = (n: number) => String(n).padStart(2, '0')
  const yyyy = d.getFullYear()
  const mm = pad(d.getMonth() + 1)
  const dd = pad(d.getDate())
  const hh = pad(d.getHours())
  const mi = pad(d.getMinutes())
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

export function formatDateShort(iso?: string | null): string {
  if (!iso) return '-'
  try {
    const d = new Date(iso)
    return d.toLocaleString()
  } catch {
    return String(iso)
  }
}
