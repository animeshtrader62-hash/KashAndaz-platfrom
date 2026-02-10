import { API_PREFIX, buildApiUrl } from './config'
import { httpRequest, jsonBody } from './http'
import type { TokenResponse } from './types'

export async function login(email: string, password: string): Promise<TokenResponse> {
  return httpRequest<TokenResponse>(buildApiUrl(`${API_PREFIX}/admin/auth/login`), {
    method: 'POST',
    body: jsonBody({ email, password }),
  })
}

export async function logout(token: string): Promise<{ ok: boolean }> {
  return httpRequest<{ ok: boolean }>(
    buildApiUrl(`${API_PREFIX}/admin/auth/logout`),
    { method: 'POST' },
    { token },
  )
}
