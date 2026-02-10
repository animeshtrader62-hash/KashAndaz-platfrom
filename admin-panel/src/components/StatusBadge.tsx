export function StatusBadge({ active }: { active: boolean }) {
  return (
    <span
      className={[
        'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold',
        active
          ? 'bg-slate-50 text-blue-600 ring-1 ring-slate-200'
          : 'bg-slate-100 text-slate-700 ring-1 ring-slate-200',
      ].join(' ')}
    >
      {active ? 'Active' : 'Inactive'}
    </span>
  )
}
