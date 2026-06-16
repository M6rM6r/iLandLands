import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gulflands/domain/entities/land_plot.dart';

/// Contract for all remote land data operations.
abstract class LandRemoteDataSource {
  Future<List<LandPlot>> getListings({
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  });

  Future<LandPlot> getListingById(String id);

  Future<List<LandPlot>> getFeaturedListings();

  Future<void> addToFavorites(String landId, String userId);

  Future<void> removeFromFavorites(String landId, String userId);

  Future<List<String>> getFavoriteIds(String userId);
}

class LandRemoteDataSourceImpl implements LandRemoteDataSource {
  LandRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('land_listings');

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection('user_favorites');

  LandPlot _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    // Normalise Firestore Timestamps to ISO strings for fromJson
    final Map<String, dynamic> json = <String, dynamic>{
      ...data,
      'id': doc.id,
      'createdAt':
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)
          ?.toDate()
          .toIso8601String(),
      // Firestore stores country as 'SA'/'UAE' etc — map to enum name expected by fromJson
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

  @override
  Future<List<LandPlot>> getListings({
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _listings.where(
      'status',
      isEqualTo: 'active',
    );

    if (country != null) {
      final String countryCode = _countryToCode(country);
      query = query.where('country', isEqualTo: countryCode);
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
      case SortOption.newest:
      case null:
        query = query.orderBy('createdAt', descending: true);
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query
        .limit(50)
        .get();
    List<LandPlot> plots = snapshot.docs.map(_fromDoc).toList();

    // Client-side search filter (Firestore doesn't support full-text)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final String q = searchQuery.toLowerCase();
      plots = plots.where((LandPlot p) {
        return p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q);
      }).toList();
    }

    return plots;
  }

  @override
  Future<LandPlot> getListingById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _listings
        .doc(id)
        .get();
    if (!doc.exists) throw Exception('Listing $id not found');
    return _fromDoc(doc);
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _listings
        .where('isFeatured', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> addToFavorites(String landId, String userId) async {
    // Use a deterministic ID to avoid duplicates
    final String docId = '${userId}_$landId';
    await _favorites.doc(docId).set(<String, dynamic>{
      'userId': userId,
      'landId': landId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFromFavorites(String landId, String userId) async {
    final String docId = '${userId}_$landId';
    await _favorites.doc(docId).delete();
  }

  @override
  Future<List<String>> getFavoriteIds(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _favorites
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              d.data()['landId'] as String,
        )
        .toList();
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
}

/// Sort options for land listings.
enum SortOption { priceAsc, priceDesc, newest, areaAsc, areaDesc }
