// =============================================================================
// Gulf Lands Backend-Aligned Types
// These types match the PHP/Python API contracts exactly.
// =============================================================================

export type UserRole = 'admin' | 'manager' | 'agent' | 'viewer';

export type TenantPlan = 'free' | 'pro' | 'enterprise';

export type UserStatus = 'active' | 'inactive' | 'suspended';

export type Country = 'saudiArabia' | 'uae' | 'qatar' | 'bahrain' | 'oman' | 'kuwait';

export type ListingStatus = 'active' | 'inactive' | 'sold' | 'pending';

export type InquiryStatus =
  | 'new'
  | 'contacted'
  | 'scheduled'
  | 'visited'
  | 'negotiating'
  | 'won'
  | 'lost'
  | 'read'
  | 'replied'
  | 'closed';

export type LeadBand = 'cold' | 'warm' | 'hot';

// ─────────────────────────────────────────────────────────────────────────────
// Auth
// ─────────────────────────────────────────────────────────────────────────────

export interface AuthUser {
  id: string;
  tenant_id: string;
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

// ─────────────────────────────────────────────────────────────────────────────
// Land Listings
// ─────────────────────────────────────────────────────────────────────────────

export interface Listing {
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
  created_at: string;
  updated_at: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Inquiries
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

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────────────────────────────────────

export interface DashboardMetrics {
  totalListings: number;
  activeListings: number;
  totalInquiries: number;
  activeInquiries: number;
  newInquiriesToday: number;
  totalUsers: number;
  wonDeals: number;
  conversionRate: number;
  avgDealValue: number;
}

export interface DashboardResponse {
  metrics: DashboardMetrics;
  pipeline: Record<string, number>;
  listingsByCountry: Record<string, number>;
}

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
// Legacy / UI-compatible aliases (for gradual migration)
// ─────────────────────────────────────────────────────────────────────────────

/** @deprecated Use InquiryStatus instead */
export type LegacyInquiryStatus = InquiryStatus;

/** @deprecated Use ListingStatus instead */
export type LegacyListingStatus = ListingStatus;

/** @deprecated Use UserRole instead */
export type LegacyUserRole = UserRole;

// Empty interfaces for components that reference old shapes
export interface Settings {
  profile: {
    name: string;
    email: string;
    phone?: string;
    avatar?: string;
  };
  notifications: {
    email: boolean;
    push: boolean;
    newInquiry: boolean;
    inquiryUpdate: boolean;
    listingApproved: boolean;
    weeklyReport: boolean;
  };
  preferences: {
    language: 'en' | 'ar';
    theme: 'light' | 'dark' | 'system';
    currency: 'USD' | 'AED' | 'SAR' | 'QAR' | 'BHD' | 'KWD' | 'OMR';
  };
}

export interface ListingsFilter {
  search?: string;
  country?: Country;
  status?: ListingStatus;
  propertyType?: string;
  minPrice?: number;
  maxPrice?: number;
  featured?: boolean;
  agentId?: string;
}

export interface SortConfig {
  field: string;
  direction: 'asc' | 'desc';
}
