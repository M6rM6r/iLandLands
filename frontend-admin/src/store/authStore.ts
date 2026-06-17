import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User, UserRole, Settings, LoginResponse } from '../lib/types';
import api from '../lib/api';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
  setLoading: (loading: boolean) => void;
  hasPermission: (requiredRoles: UserRole[]) => boolean;
  refreshAccessToken: () => Promise<boolean>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: true,

      login: async (email: string, password: string) => {
        const data: LoginResponse = await api.post('/auth/login', { email, password });
        api.setToken(data.access_token);
        localStorage.setItem('refresh_token', data.refresh_token);

        // Fetch full user profile
        const profile: User = await api.get('/users/me');

        set({
          user: profile,
          accessToken: data.access_token,
          refreshToken: data.refresh_token,
          isAuthenticated: true,
          isLoading: false,
        });
      },

      logout: () => {
        api.setToken(null);
        localStorage.removeItem('refresh_token');
        set({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false, isLoading: false });
      },

      updateUser: (userData) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...userData } : null,
        })),

      setLoading: (loading) => set({ isLoading: loading }),

      hasPermission: (requiredRoles) => {
        const { user } = get();
        if (!user) return false;
        return requiredRoles.includes(user.role);
      },

      refreshAccessToken: async () => {
        const storedRefresh = localStorage.getItem('refresh_token');
        if (!storedRefresh) return false;
        try {
          const data = await api.post<{ access_token: string; token_type: string; expires_in: number }>(
            '/auth/refresh',
            { refresh_token: storedRefresh }
          );
          api.setToken(data.access_token);
          set({ accessToken: data.access_token, isAuthenticated: true });
          return true;
        } catch {
          get().logout();
          return false;
        }
      },
    }),
    {
      name: 'gulflands-auth',
      partialize: (state) => ({
        user: state.user,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

interface SettingsState {
  settings: Settings;
  updateSettings: (settings: Partial<Settings>) => void;
  updateProfile: (profile: Partial<Settings['profile']>) => void;
  updateNotifications: (notifications: Partial<Settings['notifications']>) => void;
  updatePreferences: (preferences: Partial<Settings['preferences']>) => void;
}

const defaultSettings: Settings = {
  profile: {
    name: '',
    email: '',
  },
  notifications: {
    email: true,
    push: true,
    newInquiry: true,
    inquiryUpdate: true,
    listingApproved: true,
    weeklyReport: true,
  },
  preferences: {
    language: 'en',
    theme: 'system',
    currency: 'AED',
  },
};

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      settings: defaultSettings,
      updateSettings: (settings) =>
        set((state) => ({
          settings: { ...state.settings, ...settings },
        })),
      updateProfile: (profile) =>
        set((state) => ({
          settings: {
            ...state.settings,
            profile: { ...state.settings.profile, ...profile },
          },
        })),
      updateNotifications: (notifications) =>
        set((state) => ({
          settings: {
            ...state.settings,
            notifications: { ...state.settings.notifications, ...notifications },
          },
        })),
      updatePreferences: (preferences) =>
        set((state) => ({
          settings: {
            ...state.settings,
            preferences: { ...state.settings.preferences, ...preferences },
          },
        })),
    }),
    {
      name: 'gulflands-settings',
    }
  )
);
