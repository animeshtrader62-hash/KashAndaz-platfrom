import { API_PREFIX, buildApiUrl } from './config'
import { httpRequest, jsonBody } from './http'
import type { TokenResponse } from './types'

export async function login(email: string, password: string): Promise<TokenResponse> {
  return httpRequest<TokenResponse>(buildApiUrl(`${API_PREFIX}/auth/login`), {
    method: 'POST',
    body: jsonBody({ email, password }),
  })
}
