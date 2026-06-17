import { create } from 'zustand';
import type { InquiryStatus, ListingsFilter, SortConfig } from '../lib/types';

interface UIState {
  sidebarCollapsed: boolean;
  listingsFilter: ListingsFilter;
  listingsSort: SortConfig;
  inquiriesFilter: { status?: InquiryStatus; search?: string };
  toggleSidebar: () => void;
  setListingsFilter: (filter: ListingsFilter) => void;
  setListingsSort: (sort: SortConfig) => void;
  setInquiriesFilter: (filter: { status?: InquiryStatus; search?: string }) => void;
  resetFilters: () => void;
}

export const useUIStore = create<UIState>((set) => ({
  sidebarCollapsed: false,
  listingsFilter: {},
  listingsSort: { field: 'createdAt', direction: 'desc' },
  inquiriesFilter: {},
  toggleSidebar: () =>
    set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
  setListingsFilter: (filter) => set({ listingsFilter: filter }),
  setListingsSort: (sort) => set({ listingsSort: sort }),
  setInquiriesFilter: (filter) => set({ inquiriesFilter: filter }),
  resetFilters: () =>
    set({
      listingsFilter: {},
      inquiriesFilter: {},
      listingsSort: { field: 'createdAt', direction: 'desc' },
    }),
}));
