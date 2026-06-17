import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _cacheManager = cacheManager;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final CacheManager _cacheManager;

  static const String _listingsCacheKey = 'land_listings';
  static const String _featuredCacheKey = 'featured_listings';
  static const String _favoritesCacheKey = 'favorite_ids';
  static const Duration _cacheTtl = Duration(hours: 1);

  CollectionReference<Map<String, dynamic>> get _listingsCol =>
      _db.collection('land_listings');
  CollectionReference<Map<String, dynamic>> get _favoritesCol =>
      _db.collection('user_favorites');

  LandPlot _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    final Map<String, dynamic> json = <String, dynamic>{
      ...data,
      'id': doc.id,
      'createdAt':
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)
          ?.toDate()
          .toIso8601String(),
      'country': _normaliseCountry(data['country'] as String? ?? ''),
      'imageUrls': (data['imageUrls'] as List<dynamic>?) ?? <dynamic>[],
      'isFeatured': data['isFeatured'] ?? false,
    };
    return LandPlot.fromJson(json);
  }

  String _normaliseCountry(String raw) {
    const Map<String, String> map = <String, String>{
      'SA': 'saudiArabia',
      'UAE': 'uae',
      'QA': 'qatar',
      'BH': 'bahrain',
      'OM': 'oman',
      'KW': 'kuwait',
    };
    return map[raw.toUpperCase()] ?? raw;
  }

  String _countryToCode(Country country) {
    const Map<Country, String> map = <Country, String>{
      Country.saudiArabia: 'SA',
      Country.uae: 'UAE',
      Country.qatar: 'QA',
      Country.bahrain: 'BH',
      Country.oman: 'OM',
      Country.kuwait: 'KW',
    };
    return map[country] ?? 'SA';
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
      final List<dynamic>? cachedListings = await _cacheManager
          .get<List<dynamic>>(cacheKey);
      if (cachedListings != null) {
        return cachedListings
            .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    try {
      Query<Map<String, dynamic>> query = _listingsCol.where(
        'status',
        isEqualTo: 'active',
      );

      if (country != null) {
        query = query.where('country', isEqualTo: _countryToCode(country));
      }

      switch (sortBy) {
        case SortOption.priceAsc:
          query = query.orderBy('price');
        case SortOption.priceDesc:
          query = query.orderBy('price', descending: true);
        case SortOption.areaAsc:
          query = query.orderBy('area');
        case SortOption.areaDesc:
          query = query.orderBy('area', descending: true);
        case SortOption.oldest:
          query = query.orderBy('createdAt');
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .limit(50)
          .get();
      List<LandPlot> plots = snapshot.docs.map(_fromDoc).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final String q = searchQuery.toLowerCase();
        plots = plots.where((LandPlot p) {
          return p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q);
        }).toList();
      }

      final List<Map<String, dynamic>> listingsJson = plots
          .map((LandPlot p) => p.toJson())
          .toList();
      await _cacheManager.set(cacheKey, listingsJson, ttl: _cacheTtl);
      return plots;
    } catch (e) {
      final List<dynamic>? cachedListings = await _cacheManager
          .get<List<dynamic>>(cacheKey);
      if (cachedListings != null) {
        return cachedListings
            .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<LandPlot?> getLandPlotById(String id) async {
    final String cacheKey = 'land_plot_$id';

    final Map<String, dynamic>? cachedPlot = await _cacheManager
        .get<Map<String, dynamic>>(cacheKey);
    if (cachedPlot != null) {
      return LandPlot.fromJson(cachedPlot);
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _listingsCol
          .doc(id)
          .get();
      if (!doc.exists) return null;
      final LandPlot plot = _fromDoc(doc);
      await _cacheManager.set(cacheKey, plot.toJson(), ttl: _cacheTtl);
      return plot;
    } catch (e) {
      final Map<String, dynamic>? cachedPlot = await _cacheManager
          .get<Map<String, dynamic>>(cacheKey);
      if (cachedPlot != null) return LandPlot.fromJson(cachedPlot);
      return null;
    }
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    final List<dynamic>? cachedFeatured = await _cacheManager
        .get<List<dynamic>>(_featuredCacheKey);
    if (cachedFeatured != null) {
      return cachedFeatured
          .map((dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _listingsCol
          .where('isFeatured', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final List<LandPlot> featured = snapshot.docs.map(_fromDoc).toList();
      final List<Map<String, dynamic>> featuredJson = featured
          .map((LandPlot p) => p.toJson())
          .toList();
      await _cacheManager.set(_featuredCacheKey, featuredJson, ttl: _cacheTtl);
      return featured;
    } catch (e) {
      final List<dynamic>? cachedFeatured = await _cacheManager
          .get<List<dynamic>>(_featuredCacheKey);
      if (cachedFeatured != null) {
        return cachedFeatured
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
