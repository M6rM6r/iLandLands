import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gulflands/core/config/app_config.dart';
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
    required CacheManager cacheManager,
    ApiClient? apiClient,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _apiClient = apiClient ?? ApiClientImpl(),
       _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _cacheManager = cacheManager;

  final ApiClient _apiClient;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final CacheManager _cacheManager;

  static const String _listingsCacheKey = 'land_listings';
  static const String _featuredCacheKey = 'featured_listings';
  static const String _favoritesCacheKey = 'favorite_ids';
  static const Duration _cacheTtl = Duration(hours: 1);

  CollectionReference<Map<String, dynamic>> get _favoritesCol =>
      _db.collection('user_favorites');

  /// Map Flutter SortOption values to PHP API sort params.
  String? _mapSort(SortOption? sortBy) {
    return switch (sortBy) {
      SortOption.priceAsc => 'priceAsc',
      SortOption.priceDesc => 'priceDesc',
      SortOption.areaAsc => 'areaAsc',
      SortOption.areaDesc => 'areaDesc',
      _ => null,
    };
  }

  List<LandPlot> _parseListingsResponse(dynamic response) {
    if (response is! Map<String, dynamic>) return <LandPlot>[];
    if (response['success'] != true) return <LandPlot>[];
    final data = response['data'];
    if (data is! List<dynamic>) return <LandPlot>[];
    return data
        .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh = false,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final String cacheKey = _generateCacheKey(country, sortBy, searchQuery);

    if (!forceRefresh) {
      final List<dynamic>? cached = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        return cached
            .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    try {
      final Map<String, String> query = <String, String>{};
      if (country != null) query['country'] = country.name;
      final sort = _mapSort(sortBy);
      if (sort != null) query['sort'] = sort;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query['search'] = searchQuery;
      }

      final String qs = query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final String endpoint = '/land-listings${qs.isNotEmpty ? '?$qs' : ''}';

      final dynamic response = await _apiClient.get(endpoint);
      final List<LandPlot> plots = _parseListingsResponse(response);

      final List<Map<String, dynamic>> listingsJson = plots.map((p) => p.toJson()).toList();
      await _cacheManager.set(cacheKey, listingsJson, ttl: _cacheTtl);
      return plots;
    } catch (e) {
      final List<dynamic>? cached = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        return cached
            .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return <LandPlot>[];
    }
  }

  @override
  Future<LandPlot?> getLandPlotById(String id) async {
    final String cacheKey = 'land_plot_$id';

    final Map<String, dynamic>? cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return LandPlot.fromJson(cached);

    try {
      final dynamic response = await _apiClient.get('/land-listings/$id');
      if (response is! Map<String, dynamic>) return null;
      if (response['success'] != true) return null;
      final data = response['data'];
      if (data is! Map<String, dynamic>) return null;
      final plot = LandPlot.fromJson(data);
      await _cacheManager.set(cacheKey, plot.toJson(), ttl: _cacheTtl);
      return plot;
    } catch (e) {
      final Map<String, dynamic>? cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return LandPlot.fromJson(cached);
      return null;
    }
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    final List<dynamic>? cached = await _cacheManager.get<List<dynamic>>(_featuredCacheKey);
    if (cached != null) {
      return cached
          .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      // Load active listings and filter for featured client-side
      final dynamic response = await _apiClient.get('/land-listings');
      final List<LandPlot> all = _parseListingsResponse(response);
      final List<LandPlot> featured = all.where((p) => p.isFeatured).toList();

      final List<Map<String, dynamic>> featuredJson = featured.map((p) => p.toJson()).toList();
      await _cacheManager.set(_featuredCacheKey, featuredJson, ttl: _cacheTtl);
      return featured;
    } catch (e) {
      final List<dynamic>? cached = await _cacheManager.get<List<dynamic>>(_featuredCacheKey);
      if (cached != null) {
        return cached
            .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return <LandPlot>[];
    }
  }

  @override
  Future<void> addToFavorites(String landId) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final String docId = '${uid}_$landId';
    await _favoritesCol.doc(docId).set(<String, dynamic>{
      'userId': uid,
      'landId': landId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final List<String> favoriteIds = await getFavoriteIds();
    if (!favoriteIds.contains(landId)) {
      favoriteIds.add(landId);
      await _cacheManager.set(_favoritesCacheKey, favoriteIds);
    }
  }

  @override
  Future<void> removeFromFavorites(String landId) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final String docId = '${uid}_$landId';
    await _favoritesCol.doc(docId).delete();

    final List<String> favoriteIds = await getFavoriteIds();
    favoriteIds.remove(landId);
    await _cacheManager.set(_favoritesCacheKey, favoriteIds);
  }

  @override
  Future<List<String>> getFavoriteIds() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return <String>[];

    final List<dynamic>? cached = await _cacheManager.get<List<dynamic>>(
      _favoritesCacheKey,
    );
    if (cached != null) return cached.cast<String>();

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _favoritesCol
        .where('userId', isEqualTo: uid)
        .get();
    final List<String> ids = snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              d.data()['landId'] as String,
        )
        .toList();
    await _cacheManager.set(_favoritesCacheKey, ids);
    return ids;
  }

  String _generateCacheKey(
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  ) {
    final List<String> parts = <String>[_listingsCacheKey];
    if (country != null) parts.add(country.name);
    if (sortBy != null) parts.add(sortBy.value);
    if (searchQuery != null && searchQuery.isNotEmpty) parts.add(searchQuery);
    return parts.join('_');
  }
}
