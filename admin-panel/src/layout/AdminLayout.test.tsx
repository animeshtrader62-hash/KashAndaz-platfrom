import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

async function renderLayout(role: 'viewer' | 'admin' | 'super_admin', initialPath = '/dashboard') {
  vi.resetModules()
  vi.doMock('../auth/AuthContext', () => {
    return {
      useAuth: () => ({
        user: { email: 'x@example.com', role },
        logout: vi.fn(),
      }),
    }
  })

  const { AdminLayout } = await import('./AdminLayout')

  render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Routes>
        <Route element={<AdminLayout />}>
          <Route path="/dashboard" element={<div>Dashboard Content</div>} />
          <Route path="/claims" element={<div>Claims Content</div>} />
          <Route path="/users" element={<div>Users Content</div>} />
          <Route path="/stores" element={<div>Stores Content</div>} />
          <Route path="/offers" element={<div>Offers Content</div>} />
          <Route path="/banners" element={<div>Banners Content</div>} />
        </Route>
      </Routes>
    </MemoryRouter>,
  )
}

describe('AdminLayout nav visibility', () => {
  it('viewer sees Dashboard + Claims only', async () => {
    await renderLayout('viewer', '/dashboard')
    expect(screen.getAllByText('Dashboard').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Claims').length).toBeGreaterThan(0)

    expect(screen.queryByText('Users')).not.toBeInTheDocument()
    expect(screen.queryByText('Stores')).not.toBeInTheDocument()
    expect(screen.queryByText('Offers')).not.toBeInTheDocument()
    expect(screen.queryByText('Banners')).not.toBeInTheDocument()
  })

  it('super_admin sees Users', async () => {
    await renderLayout('super_admin', '/dashboard')
    expect(screen.getAllByText('Users').length).toBeGreaterThan(0)
  })
})
