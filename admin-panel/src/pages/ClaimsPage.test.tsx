import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

type Role = 'viewer' | 'admin' | 'super_admin'

async function renderClaimsPage(role: Role) {
  vi.resetModules()

  vi.doMock('../auth/AuthContext', () => {
    return {
      useAuth: () => ({
        token: 't',
        user: { email: `${role}@example.com`, role },
        handleApiError: vi.fn(),
      }),
    }
  })

  vi.doMock('../components/ToastProvider', () => {
    return {
      useToast: () => ({
        success: vi.fn(),
        info: vi.fn(),
        error: vi.fn(),
      }),
    }
  })

  vi.doMock('../api/admin', () => {
    return {
      adminApi: {
        listClaims: vi.fn().mockResolvedValue({
          claims: [
            {
              id: 'c1',
              user_id: 'u1',
              store_id: 's1',
              order_id: 'o1',
              status: 'pending',
              created_at: null,
              resolved_at: null,
            },
          ],
          pagination: { current_page: 1, total_pages: 1, total_items: 1 },
        }),
        claimAudit: vi.fn(),
        approveClaim: vi.fn(),
        rejectClaim: vi.fn(),
      },
    }
  })

  const { ClaimsPage } = await import('./ClaimsPage')

  render(
    <MemoryRouter>
      <ClaimsPage />
    </MemoryRouter>,
  )
}

describe('ClaimsPage role gating', () => {
  it('viewer does not see destructive buttons', async () => {
    await renderClaimsPage('viewer')

    expect(await screen.findByText('Claims / Missing Cashback')).toBeInTheDocument()
    expect(await screen.findByText('o1')).toBeInTheDocument()

    expect(screen.queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Reject' })).not.toBeInTheDocument()
  })

  it('admin sees destructive buttons', async () => {
    await renderClaimsPage('admin')

    expect(await screen.findByText('Claims / Missing Cashback')).toBeInTheDocument()
    expect(await screen.findByText('o1')).toBeInTheDocument()

    expect(screen.getByRole('button', { name: 'Approve' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Reject' })).toBeInTheDocument()
  })
})
