import api from './api';
import type { Listing, ListingStatus, Country } from './types';

interface ListingsResponse {
  success: boolean;
  data: Listing[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

interface SingleListingResponse {
  success: boolean;
  data: Listing;
}

interface CreateListingInput {
  title: string;
  description: string;
  price: number;
  area: number;
  country: Country;
  location: string;
  image_urls?: string[];
  is_featured?: boolean;
  status?: ListingStatus;
}

export const listingsApi = {
  async getAll(params?: {
    search?: string;
    country?: string;
    status?: string;
    page?: number;
    limit?: number;
  }): Promise<ListingsResponse> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.country && params.country !== 'all') query.set('country', params.country);
    if (params?.status && params.status !== 'all') query.set('status', params.status);
    if (params?.page) query.set('page', String(params.page));
    if (params?.limit) query.set('limit', String(params.limit));

    const qs = query.toString();
    return api.get<ListingsResponse>(`/land-listings${qs ? '?' + qs : ''}`);
  },

  async getFeatured(): Promise<ListingsResponse> {
    return api.get<ListingsResponse>('/land-listings/featured');
  },

  async getById(id: string): Promise<SingleListingResponse> {
    return api.get<SingleListingResponse>(`/land-listings/${id}`);
  },

  async create(data: CreateListingInput): Promise<{ success: boolean; id?: string; error?: string }> {
    return api.post('/land-listings', data);
  },

  async update(id: string, data: Partial<CreateListingInput>): Promise<{ success: boolean; error?: string }> {
    return api.put(`/land-listings/${id}`, data);
  },

  async delete(id: string): Promise<{ success: boolean; error?: string }> {
    return api.delete(`/land-listings/${id}`);
  },
};

export default listingsApi;
