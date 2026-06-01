import 'package:gulflands/core/network/api_client.dart';
import 'package:gulflands/domain/entities/land_plot.dart';

/// Contract for all remote (API) land data operations.
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
  const LandRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<LandPlot>> getListings({
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final params = <String, String>{};
    if (country != null) params['country'] = country.name;
    if (sortBy != null) params['sort'] = sortBy.name;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    final queryString = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _apiClient.get('/land-listings$queryString');
    final List<dynamic> data =
        (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

    return data
        .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LandPlot> getListingById(String id) async {
    final response = await _apiClient.get('/land-listings/$id');
    return LandPlot.fromJson(
      (response as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    final response = await _apiClient.get('/land-listings/featured');
    final List<dynamic> data =
        (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

    return data
        .map((json) => LandPlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addToFavorites(String landId, String userId) async {
    await _apiClient.post('/favorites', {'land_id': landId, 'user_id': userId});
  }

  @override
  Future<void> removeFromFavorites(String landId, String userId) async {
    await _apiClient.delete('/favorites/$landId');
  }

  @override
  Future<List<String>> getFavoriteIds(String userId) async {
    final response = await _apiClient.get('/favorites?user_id=$userId');
    final List<dynamic> data =
        (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => e['land_id'] as String).toList();
  }
}

/// Pseudo-enum for sort options — mirrors backend contract.
enum SortOption { priceAsc, priceDesc, newest, areaAsc, areaDesc }
