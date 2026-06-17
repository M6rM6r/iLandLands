import { useAuthStore } from '../store/authStore';
import type { UserRole } from '../lib/types';
import { Navigate, useLocation } from 'react-router-dom';
import { ReactNode } from 'react';

export function useAuth() {
  const { user, isAuthenticated, isLoading, login, logout, hasPermission } = useAuthStore();
  return { user, isAuthenticated, isLoading, login, logout, hasPermission };
}

export function useRequireAuth(allowedRoles?: UserRole[]) {
  const { user, isAuthenticated, isLoading, hasPermission } = useAuth();

  if (isLoading) {
    return { loading: true };
  }

  if (!isAuthenticated) {
    return { redirect: '/login' };
  }

  if (allowedRoles && !hasPermission(allowedRoles)) {
    return { redirect: '/unauthorized' };
  }

  return { user, loading: false };
}

interface ProtectedRouteProps {
  children: ReactNode;
  allowedRoles?: UserRole[];
}

export function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, hasPermission } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (allowedRoles && !hasPermission(allowedRoles)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
}
