export function SkeletonTable({ rows = 6, cols = 4 }: { rows?: number; cols?: number }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
      <div className="divide-y divide-slate-100">
        {Array.from({ length: rows }).map((_, r) => (
          <div key={r} className="grid grid-cols-12 gap-3 px-4 py-3">
            {Array.from({ length: cols }).map((__, c) => (
              <div
                key={c}
                className={
                  'h-3 rounded bg-slate-100 ' +
                  (c === 0 ? 'col-span-4' : c === 1 ? 'col-span-3' : 'col-span-2')
                }
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}
