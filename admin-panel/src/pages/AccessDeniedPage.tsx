import { Link } from 'react-router-dom'

export function AccessDeniedPage() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-8">
      <div className="text-sm font-semibold uppercase tracking-wide text-slate-500">
        KashAndaz
      </div>
      <h1 className="mt-2 text-2xl font-bold text-slate-900">Access denied</h1>
      <p className="mt-2 text-sm text-slate-600">
        Your account does not have admin access.
      </p>

      <div className="mt-6 flex gap-2">
        <Link
          to="/"
          className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
        >
          Go to dashboard
        </Link>
      </div>
    </div>
  )
}
