# Gulf Lands API Contracts

> **Version:** 1.0.0  
> **Last Updated:** 2024-06-17  
> **Base URLs:**
> - PHP API (primary): `https://api.gulflands.com/api/v1` (or local Docker: `http://localhost/api/v1`)
> - Python API (valuation + listings): `https://python-api.gulflands.com/v1` (or local: `http://localhost:8000/v1`)
> - Recommendation Service: `https://reco.gulflands.com/v1`

---

## Table of Contents

1. [Authentication](#authentication)
2. [Land Listings](#land-listings)
3. [Contact Inquiries (Kanban Pipeline)](#contact-inquiries)
4. [Analytics Events](#analytics-events)
5. [Valuation Engine (Python)](#valuation-engine)
6. [Search](#search)
7. [Favorites](#favorites)
8. [Payments](#payments)
9. [Common Types](#common-types)
10. [Error Codes](#error-codes)

---

## Authentication

All protected routes require a `Bearer` token in the `Authorization` header.

```http
Authorization: Bearer <access_token>
```

### POST `/auth/register`
**Public** — Create a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "country": "uae"
}
```

**Response 201:**
```json
{
  "id": "u0000000-0000-0000-0000-000000000001",
  "email": "user@example.com",
  "country": "uae"
}
```

### POST `/auth/login`
**Public** — Exchange credentials for JWT access + refresh tokens.

**Request:**
```json
{
  "email": "admin@gulflands.dev",
  "password": "admin123"
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": "u0000000-0000-0000-0000-000000000001",
    "email": "admin@gulflands.dev",
    "country": "uae",
    "role": "admin"
  }
}
```

**Roles:** `admin` | `manager` | `agent` | `viewer`

### POST `/auth/refresh`
**Public** — Exchange a valid refresh token for a new access token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## Land Listings

### GET `/land-listings`
**Public** — List all listings with filtering and pagination.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `country` | string | Filter by country (`saudiArabia`, `uae`, `qatar`, `bahrain`, `oman`, `kuwait`) |
| `min_price` | float | Minimum price |
| `max_price` | float | Maximum price |
| `min_area` | float | Minimum area (sqm) |
| `max_area` | float | Maximum area (sqm) |
| `status` | string | `active`, `inactive`, `sold`, `pending` |
| `is_featured` | boolean | Featured listings only |
| `page` | int | Page number (default: 1) |
| `limit` | int | Items per page (default: 20, max: 100) |
| `sort_by` | string | `createdAt`, `price`, `area` |
| `sort_order` | string | `asc`, `desc` |

**Response 200:**
```json
{
  "data": [
    {
      "id": "1",
      "tenant_id": "a0000000-0000-0000-0000-000000000001",
      "title": "Prime Coastal Land in Jeddah",
      "description": "A stunning piece of land with direct access to the Red Sea...",
      "price": 5000000.00,
      "area": 10000.00,
      "country": "saudiArabia",
      "location": "Jeddah, Obhur",
      "image_urls": ["https://images.unsplash.com/photo-xxx?w=800"],
      "is_featured": true,
      "status": "active",
      "created_at": "2023-01-01T00:00:00Z",
      "updated_at": "2023-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 10,
    "pages": 1
  }
}
```

### GET `/land-listings/{id}`
**Public** — Get a single listing by ID.

**Response 200:** Returns a single `LandListing` object.

### GET `/land-listings/featured`
**Public** — Get featured listings.

### GET `/land-listings/{id}/description`
**Auth Required** — Generate AI description for a listing.

**Response 200:**
```json
{
  "description": "AI-generated marketing description..."
}
```

### POST `/land-listings/{id}/description/invalidate`
**Auth Required (admin/manager)** — Invalidate cached AI description.

---

## Contact Inquiries

### POST `/inquiries`
**Public** (rate-limited) — Submit a new contact inquiry.

**Request:**
```json
{
  "name": "Ahmed Al-Rashid",
  "email": "ahmed@example.com",
  "phone": "+966501234567",
  "message": "I am interested in the Jeddah coastal plot. Is it still available?",
  "land_id": "1",
  "user_id": ""
}
```

**Response 201:**
```json
{
  "id": "inq-uuid-here",
  "status": "new",
  "lead_score": 78,
  "lead_band": "hot"
}
```

### GET `/inquiries`
**Auth Required (admin/manager/agent)** — List inquiries with pagination.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | Filter by status |
| `land_id` | string | Filter by listing |
| `page` | int | Page number |
| `limit` | int | Items per page |

**Response 200:**
```json
{
  "data": [
    {
      "id": "inq-uuid",
      "land_id": "1",
      "name": "Ahmed Al-Rashid",
      "email": "ahmed@example.com",
      "phone": "+966501234567",
      "message_preview": "I am interested in the Jeddah...",
      "status": "new",
      "lead_score": 78,
      "lead_band": "hot",
      "created_at": "2024-06-17T10:00:00Z",
      "land_title": "Prime Coastal Land in Jeddah"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "pages": 1
  }
}
```

### GET `/inquiries/{id}`
**Auth Required** — Get full inquiry details.

**Response 200:** Returns full inquiry row with `land_title` joined.

### PATCH `/inquiries/{id}`
**Auth Required** — Update inquiry status (Kanban card drag-drop).

**Request:**
```json
{
  "status": "contacted"
}
```

**Response 200:**
```json
{
  "id": "inq-uuid",
  "status": "contacted"
}
```

### Kanban Pipeline Statuses

```
new -> contacted -> scheduled -> visited -> negotiating -> won
                                          |
                                          -> lost
```

**Valid statuses:**
| Status | Kanban Column | Description |
|--------|---------------|-------------|
| `new` | New | Just submitted |
| `contacted` | Contacted | Agent reached out |
| `scheduled` | Scheduled | Site visit scheduled |
| `visited` | Visited | Client visited the plot |
| `negotiating` | Negotiating | Price/terms negotiation |
| `won` | Closed / Won | Deal closed successfully |
| `lost` | Closed / Lost | Deal lost |
| `read` | (legacy) | Marked as read |
| `replied` | (legacy) | Replied to inquiry |
| `closed` | (legacy) | Generic closed |

---

## Analytics Events

### POST `/analytics`
**Public** (rate-limited) — Track analytics events.

**Request:**
```json
{
  "event": "listing_viewed",
  "properties": {
    "listing_id": "1",
    "user_id": "u-xxx",
    "country": "uae",
    "source": "search"
  }
}
```

**Response 200:**
```json
{ "status": "ok" }
```

---

## Valuation Engine

### Python API: POST `/v1/valuation/estimate`
**Rate Limit:** 30/minute

**Request:**
```json
{
  "country": "uae",
  "area_sqm": 15000,
  "coastal_distance_km": 2.5,
  "zoning": "residential",
  "city": "dubai"
}
```

**Response 200:**
```json
{
  "estimated_value": 14500000.00,
  "currency": "AED",
  "formula": "V = P_base * Area^alpha * e^(-lambda * d) * Z_z * C_r"
}
```

**Currency mapping:**
- `saudiArabia` → `SAR`
- `uae` → `AED`
- Others → `USD`

### Python API: GET `/v1/listings`
**Query Parameters:** Same as PHP API.

**Response 200:** Array of `LandPlotContract` objects.

### Python API: GET `/v1/listings/{listing_id}`
**Response 200:** Single `LandPlotContract` object.

---

## Search

### GET `/search`
**Public** — Full-text search across listings.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Search query |
| `country` | string | Filter by country |
| `page` | int | Page number |
| `limit` | int | Items per page |

**Response 200:** Same shape as `GET /land-listings`.

---

## Favorites

### POST `/favorites`
**Auth Required** — Add a listing to favorites.

**Request:**
```json
{
  "land_id": "1"
}
```

### GET `/favorites`
**Auth Required** — Get user's favorites.

### DELETE `/favorites/{id}`
**Auth Required** — Remove a favorite.

---

## Payments

### POST `/payments/initiate`
**Auth Required** — Initiate a payment via Telr.

**Request:**
```json
{
  "amount": 5000,
  "currency": "AED",
  "description": "Listing fee for plot #123"
}
```

### GET `/payments/{orderId}`
**Auth Required** — Check payment status.

---

## Common Types

### LandListing
```typescript
interface LandListing {
  id: string;
  tenant_id: string;
  title: string;
  description: string;
  price: number;
  area: number;
  country: 'saudiArabia' | 'uae' | 'qatar' | 'bahrain' | 'oman' | 'kuwait';
  location: string;
  image_urls: string[];
  is_featured: boolean;
  status: 'active' | 'inactive' | 'sold' | 'pending';
  created_at: string; // ISO 8601
  updated_at: string;
}
```

### Inquiry
```typescript
interface Inquiry {
  id: string;
  land_id: string | null;
  user_id: string | null;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  status: 'new' | 'contacted' | 'scheduled' | 'visited' | 'negotiating' | 'won' | 'lost' | 'read' | 'replied' | 'closed';
  lead_score: number;
  lead_band: 'cold' | 'warm' | 'hot';
  created_at: string;
  updated_at: string;
  land_title?: string;
}
```

### User
```typescript
interface User {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  phone: string | null;
  role: 'admin' | 'manager' | 'agent' | 'viewer';
  country: string | null;
  status: 'active' | 'inactive' | 'suspended';
  email_verified: boolean;
  created_at: string;
}
```

### PaginatedResponse<T>
```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}
```

---

## Error Codes

| HTTP Status | Code | Meaning |
|-------------|------|---------|
| 400 | `bad_request` | Invalid request parameters |
| 401 | `unauthorized` | Missing or invalid token |
| 403 | `forbidden` | Valid token but insufficient permissions |
| 404 | `not_found` | Resource not found |
| 409 | `conflict` | Resource already exists (e.g., duplicate email) |
| 422 | `validation_error` | Validation failed |
| 429 | `rate_limited` | Too many requests |
| 500 | `internal_error` | Server error |

**Error Response Shape:**
```json
{
  "error": "validation_error",
  "message": "Password must be at least 10 characters"
}
```

---

## Frontend Integration Notes

### Environment Variables
```bash
# Admin Dashboard (.env)
VITE_API_BASE_URL=https://api.gulflands.com/api/v1
VITE_PYTHON_API_URL=https://python-api.gulflands.com/v1
VITE_RECO_SERVICE_URL=https://reco.gulflands.com/v1
VITE_APP_NAME="Gulf Lands Admin"

# Landing Page (.env)
VITE_API_BASE_URL=https://api.gulflands.com/api/v1
VITE_APP_NAME="Gulf Lands"
```

### TanStack Query Keys
```typescript
// Listings
['listings', { page, limit, filters }]
['listing', id]
['featured-listings']

// Inquiries
['inquiries', { page, limit, status }]
['inquiry', id]

// Analytics
['analytics-summary']
['analytics-events']

// Users
['users']
['user', id]
```

## Users

### GET `/users`
**Auth Required (admin/manager)** — List users with pagination and filters.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `role` | string | Filter by role (`admin`, `manager`, `agent`, `viewer`) |
| `status` | string | Filter by status (`active`, `inactive`, `suspended`) |
| `page` | int | Page number (default: 1) |
| `limit` | int | Items per page (default: 20, max: 100) |

**Response 200:**
```json
{
  "data": [
    {
      "id": "u0000000-0000-0000-0000-000000000001",
      "email": "admin@gulflands.dev",
      "first_name": "Admin",
      "last_name": "User",
      "phone": "+971501234567",
      "role": "admin",
      "country": "uae",
      "status": "active",
      "email_verified": false,
      "created_at": "2024-06-17T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "pages": 1
  }
}
```

### GET `/users/me`
**Auth Required** — Current authenticated user profile.

**Response 200:** Returns full `User` object.

### PATCH `/users/me`
**Auth Required** — Update own profile.

**Request:**
```json
{
  "first_name": "Ahmed",
  "last_name": "Al-Rashid",
  "phone": "+966501234567",
  "country": "saudiArabia"
}
```

**Response 200:**
```json
{ "updated": true }
```

### GET `/users/{id}`
**Auth Required (admin/manager)** — Get single user.

**Response 200:** Returns `User` object.

### PATCH `/users/{id}`
**Auth Required (admin/manager)** — Update user. Managers cannot change roles or modify admins.

**Request:**
```json
{
  "first_name": "Updated",
  "status": "active",
  "role": "manager"
}
```

**Response 200:**
```json
{ "id": "u-xxx", "updated": true }
```

### DELETE `/users/{id}`
**Auth Required (admin)** — Soft-delete user (sets status to `inactive`). Self-deletion is blocked.

**Response 200:**
```json
{ "id": "u-xxx", "deleted": true }
```

---

## Dashboard

### GET `/dashboard/metrics`
**Auth Required (admin/manager/agent)** — Aggregated KPIs for the admin dashboard.

**Response 200:**
```json
{
  "metrics": {
    "totalListings": 150,
    "activeListings": 120,
    "totalInquiries": 450,
    "activeInquiries": 85,
    "newInquiriesToday": 12,
    "totalUsers": 32,
    "wonDeals": 28,
    "conversionRate": 6.22,
    "avgDealValue": 7850000.00
  },
  "pipeline": {
    "new": 15,
    "contacted": 22,
    "scheduled": 8,
    "visited": 5,
    "negotiating": 3,
    "won": 28,
    "lost": 12
  },
  "listingsByCountry": {
    "saudiArabia": 45,
    "uae": 38,
    "qatar": 22,
    "bahrain": 8,
    "oman": 4,
    "kuwait": 3
  }
}
```

### GET `/dashboard/inquiry-pipeline`
**Auth Required (admin/manager/agent)** — Inquiry counts grouped by status.

**Response 200:**
```json
{
  "pipeline": {
    "new": 15,
    "contacted": 22,
    "scheduled": 8,
    "visited": 5,
    "negotiating": 3,
    "won": 28,
    "lost": 12
  }
}
```

### GET `/dashboard/recent-activity`
**Auth Required (admin/manager/agent)** — Recent analytics events.

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `limit` | int | Max events (default: 20, max: 50) |

**Response 200:**
```json
{
  "events": [
    {
      "event_name": "listing_viewed",
      "user_id": "u-xxx",
      "properties": { "listing_id": "1" },
      "created_at": "2024-06-17T10:00:00Z"
    }
  ]
}
```

---

## Land Listings (Admin CRUD)

### POST `/land-listings`
**Auth Required (admin/manager/agent)** — Create a new listing.

**Request:**
```json
{
  "title": "New Plot in Riyadh",
  "description": "Prime commercial land...",
  "price": 8500000.00,
  "area": 12000.00,
  "country": "saudiArabia",
  "location": "Riyadh, Al-Malqa District",
  "image_urls": ["https://example.com/img1.jpg"],
  "is_featured": false,
  "status": "active"
}
```

**Response 201:**
```json
{
  "success": true,
  "id": "new-listing-uuid"
}
```

### PUT `/land-listings/{id}`
**Auth Required (admin/manager)** — Update a listing.

**Request:** Same shape as POST; send only fields to update.

**Response 200:**
```json
{
  "success": true,
  "id": "listing-uuid"
}
```

### DELETE `/land-listings/{id}`
**Auth Required (admin/manager)** — Soft-delete a listing (sets status to `inactive`).

**Response 200:**
```json
{
  "success": true,
  "id": "listing-uuid",
  "message": "Listing deactivated"
}
```

---

### Route Guards
- `/login` — Public
- `/dashboard/*` — Requires `access_token` + role in [`admin`, `manager`, `agent`]
- `/dashboard/settings/users` — Requires role `admin`
- `/dashboard/analytics` — Requires role `admin` or `manager`
