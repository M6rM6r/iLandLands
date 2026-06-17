// =============================================================================
// Gulf Lands Shared TypeScript API Types
// =============================================================================
// These types mirror the backend contracts (PHP + Python APIs).
// Copy this file into any frontend project (Bolt, Lovable, Flutter web, etc.)
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// Core Enums
// ─────────────────────────────────────────────────────────────────────────────

export type Country =
  | 'saudiArabia'
  | 'uae'
  | 'qatar'
  | 'bahrain'
  | 'oman'
  | 'kuwait';

export type UserRole = 'admin' | 'manager' | 'agent' | 'viewer';

export type UserStatus = 'active' | 'inactive' | 'suspended';

export type ListingStatus = 'active' | 'inactive' | 'sold' | 'pending';

// Pipeline statuses for Kanban board
export type InquiryStatus =
  | 'new'
  | 'contacted'
  | 'scheduled'
  | 'visited'
  | 'negotiating'
  | 'won'
  | 'lost'
  | 'read'      // legacy
  | 'replied'   // legacy
  | 'closed';   // legacy

export type LeadBand = 'cold' | 'warm' | 'hot';

export type TenantPlan = 'free' | 'pro' | 'enterprise';

// ─────────────────────────────────────────────────────────────────────────────
// Pagination
// ─────────────────────────────────────────────────────────────────────────────

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: PaginationMeta;
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth
// ─────────────────────────────────────────────────────────────────────────────

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  country: Country;
}

export interface AuthUser {
  id: string;
  email: string;
  country: string | null;
  role: UserRole;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: 'Bearer';
  expires_in: number;
  user: AuthUser;
}

export interface RefreshRequest {
  refresh_token: string;
}

export interface RefreshResponse {
  access_token: string;
  token_type: 'Bearer';
  expires_in: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Land Listings
// ─────────────────────────────────────────────────────────────────────────────

export interface LandListing {
  id: string;
  tenant_id: string;
  title: string;
  description: string;
  price: number;
  area: number;
  country: Country;
  location: string;
  image_urls: string[];
  is_featured: boolean;
  status: ListingStatus;
  created_at: string; // ISO 8601
  updated_at: string;
}

export interface ListingFilters {
  country?: Country;
  min_price?: number;
  max_price?: number;
  min_area?: number;
  max_area?: number;
  status?: ListingStatus;
  is_featured?: boolean;
  sort_by?: 'createdAt' | 'price' | 'area';
  sort_order?: 'asc' | 'desc';
  page?: number;
  limit?: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Inquiries (Kanban Pipeline)
// ─────────────────────────────────────────────────────────────────────────────

export interface Inquiry {
  id: string;
  land_id: string | null;
  user_id: string | null;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  status: InquiryStatus;
  lead_score: number;
  lead_band: LeadBand;
  created_at: string;
  updated_at: string;
  land_title?: string;
}

export interface InquiryPreview {
  id: string;
  land_id: string | null;
  name: string;
  email: string;
  phone: string | null;
  message_preview: string;
  status: InquiryStatus;
  lead_score: number;
  lead_band: LeadBand;
  created_at: string;
  land_title: string | null;
}

export interface CreateInquiryRequest {
  name: string;
  email: string;
  phone?: string;
  message: string;
  land_id?: string;
  user_id?: string;
}

export interface UpdateInquiryRequest {
  status: InquiryStatus;
}

export interface InquiryFilters {
  status?: InquiryStatus;
  land_id?: string;
  page?: number;
  limit?: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

export interface User {
  id: string;
  tenant_id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  phone: string | null;
  role: UserRole;
  country: Country | null;
  status: UserStatus;
  email_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserFilters {
  role?: UserRole;
  status?: UserStatus;
  page?: number;
  limit?: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics
// ─────────────────────────────────────────────────────────────────────────────

export interface AnalyticsEvent {
  event: string;
  properties: Record<string, unknown>;
}

export interface AnalyticsEventBatch {
  events: AnalyticsEvent[];
}

export interface AnalyticsSummary {
  tenant_id: string;
  date: string;
  event_name: string;
  cnt: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Valuation (Python API)
// ─────────────────────────────────────────────────────────────────────────────

export interface ValuationRequest {
  country: string;
  area_sqm: number;
  coastal_distance_km: number;
  zoning: string;
  city?: string;
}

export interface ValuationResponse {
  estimated_value: number;
  currency: 'SAR' | 'AED' | 'USD';
  formula: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Favorites
// ─────────────────────────────────────────────────────────────────────────────

export interface FavoriteRequest {
  land_id: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────────────────────────────────────

export interface SearchRequest {
  q: string;
  country?: Country;
  page?: number;
  limit?: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Payments
// ─────────────────────────────────────────────────────────────────────────────

export interface PaymentInitiateRequest {
  amount: number;
  currency: 'AED' | 'SAR' | 'USD';
  description: string;
}

export interface PaymentStatus {
  id: string;
  cart_id: string;
  tenant_id: string;
  user_id: string | null;
  listing_id: string | null;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  created_at: string;
  updated_at: string | null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard / Admin
// ─────────────────────────────────────────────────────────────────────────────

export interface DashboardMetrics {
  totalListings: number;
  activeInquiries: number;
  conversionRate: number;
  avgDealValue: number;
  totalUsers: number;
  newInquiriesToday: number;
}

export interface AgentPerformance {
  user_id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  listings_posted: number;
  deals_closed: number;
  response_time_avg_minutes: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// API Error Shape
// ─────────────────────────────────────────────────────────────────────────────

export interface ApiError {
  error: string;
  message: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// TanStack Query Keys (convention)
// ─────────────────────────────────────────────────────────────────────────────

export const queryKeys = {
  listings: (filters?: ListingFilters) => ['listings', filters] as const,
  listing: (id: string) => ['listing', id] as const,
  featuredListings: () => ['featured-listings'] as const,
  inquiries: (filters?: InquiryFilters) => ['inquiries', filters] as const,
  inquiry: (id: string) => ['inquiry', id] as const,
  analyticsSummary: () => ['analytics-summary'] as const,
  analyticsEvents: () => ['analytics-events'] as const,
  users: (filters?: UserFilters) => ['users', filters] as const,
  user: (id: string) => ['user', id] as const,
  search: (params: SearchRequest) => ['search', params] as const,
  favorites: () => ['favorites'] as const,
  dashboardMetrics: () => ['dashboard-metrics'] as const,
} as const;
