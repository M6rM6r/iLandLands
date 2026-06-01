import 'package:gulflands/core/network/api_client.dart';
import 'package:gulflands/core/storage/cache_manager.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';

abstract class LandRepository {
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh = false,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  });
  
  Future<LandPlot?> getLandPlotById(String id);
  Future<List<LandPlot>> getFeaturedListings();
  Future<void> addToFavorites(String landId);
  Future<void> removeFromFavorites(String landId);
  Future<List<String>> getFavoriteIds();
}

class LandRepositoryImpl implements LandRepository {

  LandRepositoryImpl({
    required ApiClient apiClient,
    required CacheManager cacheManager,
  }) : _apiClient = apiClient,
       _cacheManager = cacheManager;
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  
  static const String _listingsCacheKey = 'land_listings';
  static const String _featuredCacheKey = 'featured_listings';
  static const String _favoritesCacheKey = 'favorite_ids';
  static const Duration _cacheTtl = Duration(hours: 1);

  @override
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh = false,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final cacheKey = _generateCacheKey(country, sortBy, searchQuery);
    
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedListings = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedListings != null) {
        return cachedListings
            .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (country != null) queryParams['country'] = country.name;
      if (sortBy != null) queryParams['sort'] = sortBy.name;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final endpoint = queryString.isNotEmpty 
          ? '/land-listings?$queryString'
          : '/land-listings';

      final response = await _apiClient.get(endpoint);
      
      if (response['data'] == null) {
        throw Exception('No data received from API');
      }

      final listingsData = response['data'] as List<dynamic>;
      final listings = listingsData
          .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache the results
      await _cacheManager.set(
        cacheKey,
        listingsData,
        ttl: _cacheTtl,
      );

      return listings;
    } catch (e) {
      // Fallback to cache if API fails
      final cachedListings = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedListings != null) {
        return cachedListings
            .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Re-throw the original error if no cache available
      rethrow;
    }
  }

  @override
  Future<LandPlot?> getLandPlotById(String id) async {
    final cacheKey = 'land_plot_$id';
    
    // Try cache first
    final cachedPlot = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
    if (cachedPlot != null) {
      return LandPlot.fromJson(cachedPlot);
    }

    try {
      final response = await _apiClient.get('/land-listings/$id');
      
      if (response['data'] == null) {
        return null;
      }

      final plotData = response['data'] as Map<String, dynamic>;
      final plot = LandPlot.fromJson(plotData);

      // Cache the result
      await _cacheManager.set(cacheKey, plotData, ttl: _cacheTtl);

      return plot;
    } catch (e) {
      // Return cached version if available
      final cachedPlot = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cachedPlot != null) {
        return LandPlot.fromJson(cachedPlot);
      }
      
      return null;
    }
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    // Try cache first
    final cachedFeatured = await _cacheManager.get<List<dynamic>>(_featuredCacheKey);
    if (cachedFeatured != null) {
      return cachedFeatured
          .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final response = await _apiClient.get('/land-listings/featured');
      
      if (response['data'] == null) {
        return [];
      }

      final featuredData = response['data'] as List<dynamic>;
      final featured = featuredData
          .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache the results
      await _cacheManager.set(
        _featuredCacheKey,
        featuredData,
        ttl: _cacheTtl,
      );

      return featured;
    } catch (e) {
      // Return cached version if available
      final cachedFeatured = await _cacheManager.get<List<dynamic>>(_featuredCacheKey);
      if (cachedFeatured != null) {
        return cachedFeatured
            .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    }
  }

  @override
  Future<void> addToFavorites(String landId) async {
    try {
      await _apiClient.post('/favorites', {'landId': landId});
      
      // Update local cache
      final favoriteIds = await getFavoriteIds();
      if (!favoriteIds.contains(landId)) {
        favoriteIds.add(landId);
        await _cacheManager.set(_favoritesCacheKey, favoriteIds);
      }
    } catch (e) {
      // Optimistic update - add to cache even if API fails
      final favoriteIds = await getFavoriteIds();
      if (!favoriteIds.contains(landId)) {
        favoriteIds.add(landId);
        await _cacheManager.set(_favoritesCacheKey, favoriteIds);
      }
      
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String landId) async {
    try {
      await _apiClient.delete('/favorites/$landId');
      
      // Update local cache
      final favoriteIds = await getFavoriteIds();
      favoriteIds.remove(landId);
      await _cacheManager.set(_favoritesCacheKey, favoriteIds);
    } catch (e) {
      // Optimistic update - remove from cache even if API fails
      final favoriteIds = await getFavoriteIds();
      favoriteIds.remove(landId);
      await _cacheManager.set(_favoritesCacheKey, favoriteIds);
      
      rethrow;
    }
  }

  @override
  Future<List<String>> getFavoriteIds() async {
    return await _cacheManager.get<List<String>>(_favoritesCacheKey) ?? [];
  }

  String _generateCacheKey(Country? country, SortOption? sortBy, String? searchQuery) {
    final parts = [_listingsCacheKey];
    if (country != null) parts.add(country.name);
    if (sortBy != null) parts.add(sortBy.name);
    if (searchQuery != null && searchQuery.isNotEmpty) parts.add(searchQuery);
    return parts.join('_');
  }
}
