import 'package:gulflands/core/storage/cache_manager.dart';
import 'package:gulflands/domain/entities/land_plot.dart';

/// Contract for all local (cache) land data operations.
abstract class LandLocalDataSource {
  Future<List<LandPlot>?> getCachedListings(String cacheKey);

  Future<void> cacheListings(String cacheKey, List<LandPlot> listings);

  Future<List<LandPlot>?> getCachedFeaturedListings();

  Future<void> cacheFeaturedListings(List<LandPlot> listings);

  Future<List<String>?> getCachedFavoriteIds(String userId);

  Future<void> cacheFavoriteIds(String userId, List<String> ids);

  Future<void> invalidate(String cacheKey);

  Future<void> clearAll();
}

class LandLocalDataSourceImpl implements LandLocalDataSource {
  const LandLocalDataSourceImpl({required CacheManager cacheManager})
    : _cacheManager = cacheManager;

  final CacheManager _cacheManager;

  static const String _featuredKey = 'featured_listings_v1';
  static const Duration _defaultTtl = Duration(hours: 1);
  static const Duration _featuredTtl = Duration(minutes: 30);

  @override
  Future<List<LandPlot>?> getCachedListings(String cacheKey) async {
    final List<dynamic>? raw = await _cacheManager.get<List<dynamic>>(cacheKey);
    if (raw == null) return null;
    try {
      return raw
          .map((e) => LandPlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await _cacheManager.remove(cacheKey);
      return null;
    }
  }

  @override
  Future<void> cacheListings(String cacheKey, List<LandPlot> listings) =>
      _cacheManager.set(
        cacheKey,
        listings.map((LandPlot p) => p.toJson()).toList(),
        ttl: _defaultTtl,
      );

  @override
  Future<List<LandPlot>?> getCachedFeaturedListings() =>
      getCachedListings(_featuredKey);

  @override
  Future<void> cacheFeaturedListings(List<LandPlot> listings) =>
      _cacheManager.set(
        _featuredKey,
        listings.map((LandPlot p) => p.toJson()).toList(),
        ttl: _featuredTtl,
      );

  @override
  Future<List<String>?> getCachedFavoriteIds(String userId) async {
    return _cacheManager.get<List<String>>('favorites_$userId');
  }

  @override
  Future<void> cacheFavoriteIds(String userId, List<String> ids) =>
      _cacheManager.set('favorites_$userId', ids, ttl: _defaultTtl);

  @override
  Future<void> invalidate(String cacheKey) => _cacheManager.remove(cacheKey);

  @override
  Future<void> clearAll() => _cacheManager.clear();
}
