import { Navigate, Route, Routes } from 'react-router-dom'
import { AdminLayout } from './layout/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { StoresPage } from './pages/StoresPage'
import { OffersPage } from './pages/OffersPage'
import { BannersPage } from './pages/BannersPage'
import { AccessDeniedPage } from './pages/AccessDeniedPage'
import { RequireAdmin } from './auth/RequireAdmin'
import { RequireRole } from './auth/RequireRole'
import { UsersPage } from './pages/UsersPage'
import { ClaimsPage } from './pages/ClaimsPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />
      <Route path="/access-denied" element={<AccessDeniedPage />} />

      <Route
        element={
          <RequireAdmin>
            <AdminLayout />
          </RequireAdmin>
        }
      >
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route
          path="/stores"
          element={
            <RequireRole allowed={['admin', 'super_admin']}>
              <StoresPage />
            </RequireRole>
          }
        />
        <Route
          path="/offers"
          element={
            <RequireRole allowed={['admin', 'super_admin']}>
              <OffersPage />
            </RequireRole>
          }
        />
        <Route
          path="/banners"
          element={
            <RequireRole allowed={['admin', 'super_admin']}>
              <BannersPage />
            </RequireRole>
          }
        />
        <Route
          path="/claims"
          element={
            <RequireRole allowed={['viewer', 'admin', 'super_admin']}>
              <ClaimsPage />
            </RequireRole>
          }
        />
        <Route
          path="/users"
          element={
            <RequireRole allowed={['super_admin']}>
              <UsersPage />
            </RequireRole>
          }
        />
      </Route>

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}
