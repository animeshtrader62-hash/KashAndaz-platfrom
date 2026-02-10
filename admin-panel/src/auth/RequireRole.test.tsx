import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

async function loadRequireRoleFor(role: 'viewer' | 'admin' | 'super_admin') {
  vi.resetModules()
  vi.doMock('./AuthContext', () => {
    return {
      useAuth: () => ({
        user: { email: `${role}@example.com`, role },
      }),
    }
  })

  return import('./RequireRole')
}

describe('RequireRole', () => {
  it('redirects viewer away from super_admin-only route', async () => {
    const { RequireRole } = await loadRequireRoleFor('viewer')

    render(
      <MemoryRouter initialEntries={['/users']}>
        <Routes>
          <Route
            path="/users"
            element={
              <RequireRole allowed={['super_admin']}>
                <div>Users Page</div>
              </RequireRole>
            }
          />
          <Route path="/access-denied" element={<div>Access Denied</div>} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Access Denied')).toBeInTheDocument()
    expect(screen.queryByText('Users Page')).not.toBeInTheDocument()
  })

  it('allows viewer when viewer is in allowed list', async () => {
    const { RequireRole } = await loadRequireRoleFor('viewer')

    render(
      <MemoryRouter initialEntries={['/claims']}>
        <Routes>
          <Route
            path="/claims"
            element={
              <RequireRole allowed={['viewer', 'admin', 'super_admin']}>
                <div>Claims Page</div>
              </RequireRole>
            }
          />
          <Route path="/access-denied" element={<div>Access Denied</div>} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Claims Page')).toBeInTheDocument()
    expect(screen.queryByText('Access Denied')).not.toBeInTheDocument()
  })
})
