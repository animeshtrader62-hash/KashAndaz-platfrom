import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

const navItems = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/stores', label: 'Stores' },
  { to: '/offers', label: 'Offers' },
  { to: '/banners', label: 'Banners' },
]

function NavItem({ to, label }: { to: string; label: string }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        [
          'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium',
          isActive
            ? 'bg-slate-900 text-white'
            : 'text-slate-700 hover:bg-slate-100 hover:text-slate-900',
        ].join(' ')
      }
    >
      <span className="h-2 w-2 rounded-full bg-current opacity-60" />
      <span>{label}</span>
    </NavLink>
  )
}

export function AdminLayout() {
  const location = useLocation()
  const { user, logout } = useAuth()

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto flex min-h-screen max-w-[1400px]">
        <aside className="hidden w-64 border-r border-slate-200 bg-white p-4 md:block">
          <div className="mb-4 rounded-xl border border-slate-200 bg-slate-50 p-3">
            <div className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              KashAndaz
            </div>
            <div className="text-lg font-semibold text-slate-900">Admin Panel</div>
            <div className="mt-2 text-xs text-slate-600">Phase 2 (Live APIs, No Storage)</div>
            <div className="mt-1 text-xs text-slate-500">Uploads are preview-only</div>
            <div className="mt-1 text-xs text-slate-500">Offer18 automation not enabled yet</div>
          </div>

          <nav className="space-y-1">
            {navItems.map((n) => (
              <NavItem key={n.to} to={n.to} label={n.label} />
            ))}
          </nav>

          <div className="mt-6 rounded-xl border border-slate-200 bg-white p-3">
            <div className="text-xs font-semibold text-slate-700">Status</div>
            <div className="mt-1 text-xs text-slate-600">
              Connected via JWT to admin APIs.
            </div>
            {user ? (
              <div className="mt-2 text-xs text-slate-500">
                Signed in as <span className="font-medium text-slate-700">{user.email}</span>
              </div>
            ) : null}
          </div>
        </aside>

        <div className="flex flex-1 flex-col">
          <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur">
            <div className="flex items-center justify-between px-4 py-3 md:px-6">
              <div>
                <div className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  {location.pathname.replace('/', '').toUpperCase() || 'DASHBOARD'}
                </div>
                <div className="text-lg font-semibold text-slate-900">
                  KashAndaz Admin
                </div>
              </div>

              <div className="flex items-center gap-2">
                <div className="hidden items-center gap-2 md:flex">
                  <span className="rounded-full border border-slate-200 bg-white px-2 py-1 text-xs font-semibold text-slate-700">
                    Phase 2
                  </span>
                  <span className="rounded-full border border-slate-200 bg-white px-2 py-1 text-xs text-slate-600">
                    No storage
                  </span>
                  <span className="rounded-full border border-slate-200 bg-white px-2 py-1 text-xs text-slate-600">
                    Uploads preview-only
                  </span>
                </div>
                <button
                  type="button"
                  className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  onClick={() => {
                    logout()
                  }}
                >
                  Logout
                </button>
              </div>
            </div>
          </header>

          <main className="flex-1 px-4 py-6 md:px-6">
            <Outlet />
          </main>
        </div>
      </div>
    </div>
  )
}
