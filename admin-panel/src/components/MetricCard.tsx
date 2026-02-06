export function MetricCard({
  title,
  value,
  subtitle,
  titleHint,
}: {
  title: string
  value: string
  subtitle?: string
  titleHint?: string
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="text-sm font-semibold text-slate-700" title={titleHint}>
        {title}
      </div>
      <div className="mt-2 text-3xl font-bold text-slate-900">{value}</div>
      {subtitle ? (
        <div className="mt-2 text-xs text-slate-500">{subtitle}</div>
      ) : null}
    </div>
  )
}
