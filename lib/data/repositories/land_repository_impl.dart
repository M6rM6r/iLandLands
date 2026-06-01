import 'package:gulflands/data/datasources/land_local_datasource.dart';
import 'package:gulflands/data/datasources/land_remote_datasource.dart';
import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/repositories/land_repository.dart';

/// Canonical implementation of [LandRepository] following clean architecture.
///
/// Strategy: serve from cache first; fall back to network on cache miss or
/// when [forceRefresh] is requested; propagate exceptions upward to the BLoC.
class LandRepositoryImpl implements LandRepository {
  const LandRepositoryImpl({
    required LandRemoteDataSource remoteDataSource,
    required LandLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final LandRemoteDataSource _remote;
  final LandLocalDataSource _local;

  @override
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh = false,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final cacheKey = _listingsCacheKey(country, sortBy, searchQuery);

    if (!forceRefresh) {
      final cached = await _local.getCachedListings(cacheKey);
      if (cached != null) return cached;
    }

    final listings = await _remote.getListings(
      country: country,
      sortBy: sortBy,
      searchQuery: searchQuery,
    );
    await _local.cacheListings(cacheKey, listings);
    return listings;
  }

  @override
  Future<LandPlot?> getLandPlotById(String id) async {
    return _remote.getListingById(id);
  }

  @override
  Future<List<LandPlot>> getFeaturedListings({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _local.getCachedFeaturedListings();
      if (cached != null) return cached;
    }

    final listings = await _remote.getFeaturedListings();
    await _local.cacheFeaturedListings(listings);
    return listings;
  }

  @override
  Future<void> addToFavorites(String landId, {String userId = ''}) async {
    await _remote.addToFavorites(landId, userId);
    // Invalidate favorites cache so next read is fresh
    await _local.invalidate('favorites_$userId');
  }

  @override
  Future<void> removeFromFavorites(String landId, {String userId = ''}) async {
    await _remote.removeFromFavorites(landId, userId);
    await _local.invalidate('favorites_$userId');
  }

  @override
  Future<List<String>> getFavoriteIds({String userId = '', bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _local.getCachedFavoriteIds(userId);
      if (cached != null) return cached;
    }

    final ids = await _remote.getFavoriteIds(userId);
    await _local.cacheFavoriteIds(userId, ids);
    return ids;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _listingsCacheKey(Country? country, SortOption? sortBy, String? search) {
    final parts = [
      'listings_v1',
      country?.name ?? 'all',
      sortBy?.name ?? 'default',
      search?.isNotEmpty == true ? search!.hashCode.toString() : 'nosearch',
    ];
    return parts.join('_');
  }
}
