import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

type NavItemDef = { to: string; label: string; roles: Array<'viewer' | 'admin' | 'super_admin'> }

const navItems: NavItemDef[] = [
  { to: '/dashboard', label: 'Dashboard', roles: ['viewer', 'admin', 'super_admin'] },
  { to: '/stores', label: 'Stores', roles: ['admin', 'super_admin'] },
  { to: '/offers', label: 'Offers', roles: ['admin', 'super_admin'] },
  { to: '/banners', label: 'Banners', roles: ['admin', 'super_admin'] },
  { to: '/claims', label: 'Claims', roles: ['viewer', 'admin', 'super_admin'] },
  { to: '/users', label: 'Users', roles: ['super_admin'] },
]

function NavItem({ to, label }: { to: string; label: string }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        [
          'flex items-center gap-3 whitespace-nowrap rounded-lg px-3 py-2 text-sm font-medium',
          isActive
            ? 'bg-blue-600 text-white'
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

  const roleRaw = String(user?.role || '').toLowerCase()
  const isKnownRole = (r: string): r is 'viewer' | 'admin' | 'super_admin' =>
    r === 'viewer' || r === 'admin' || r === 'super_admin'
  const role = isKnownRole(roleRaw) ? roleRaw : null
  const visibleNav = role ? navItems.filter((n) => n.roles.includes(role)) : navItems.slice(0, 1)

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto flex min-h-screen max-w-[1400px]">
        <aside className="hidden w-64 border-r border-slate-200 bg-white p-4 md:block">
          <div className="mb-4 rounded-xl border border-slate-200 bg-slate-50 p-3">
            <div className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              KashAndaz
            </div>
            <div className="text-lg font-semibold text-slate-900">Admin Panel</div>
          </div>

          <nav className="space-y-1">
            {visibleNav.map((n) => (
              <NavItem key={n.to} to={n.to} label={n.label} />
            ))}
          </nav>

          <div className="mt-6 rounded-xl border border-slate-200 bg-white p-3">
            <div className="text-xs font-semibold text-slate-700">Status</div>
            <div className="mt-1 text-xs text-slate-600">Authenticated</div>
            {user ? (
              <div className="mt-2 text-xs text-slate-500">
                Signed in as <span className="font-medium text-slate-700">{user.email}</span>
                {user.role ? (
                  <span className="ml-2 rounded-full border border-slate-200 bg-white px-2 py-0.5 text-[11px] font-semibold text-slate-600">
                    {String(user.role).toUpperCase()}
                  </span>
                ) : null}
              </div>
            ) : null}
          </div>
        </aside>

        <div className="flex flex-1 flex-col">
          <header className="sticky top-0 z-10 border-b border-slate-200 bg-white">
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

            <div className="border-t border-slate-200 px-4 py-2 md:hidden">
              <nav className="flex items-center gap-2 overflow-x-auto">
                {visibleNav.map((n) => (
                  <NavItem key={n.to} to={n.to} label={n.label} />
                ))}
              </nav>
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
