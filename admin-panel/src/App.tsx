import { Navigate, Route, Routes } from 'react-router-dom'
import { AdminLayout } from './layout/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { StoresPage } from './pages/StoresPage'
import { OffersPage } from './pages/OffersPage'
import { BannersPage } from './pages/BannersPage'
import { AccessDeniedPage } from './pages/AccessDeniedPage'
import { RequireAdmin } from './auth/RequireAdmin'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/access-denied" element={<AccessDeniedPage />} />

      <Route
        element={
          <RequireAdmin>
            <AdminLayout />
          </RequireAdmin>
        }
      >
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/stores" element={<StoresPage />} />
        <Route path="/offers" element={<OffersPage />} />
        <Route path="/banners" element={<BannersPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}
