import 'package:gulflands/domain/repositories/land_repository.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/services/land_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LandRepository)
class LandRepositoryImpl implements LandRepository {
  final LandService _service;

  LandRepositoryImpl(this._service);

  @override
  Future<List<LandPlot>> getListings({
    String? country,
    double? minPrice,
    double? maxPrice,
  }) async {
    final List<LandPlot> plots = await _service.getLandListings();
    return plots.where((LandPlot plot) {
      bool matches = true;
      if (country != null) matches &= plot.country.name == country;
      if (minPrice != null) matches &= plot.price >= minPrice;
      if (maxPrice != null) matches &= plot.price <= maxPrice;
      return matches;
    }).toList();
  }

  @override
  Future<LandPlot?> getDetails(String id) async {
    final List<LandPlot> plots = await _service.getLandListings();
    try {
      return plots.firstWhere((LandPlot p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveListing(LandPlot plot) => _service.addLandPlot(plot);

  @override
  Future<List<LandPlot>> getTrending() {
    // Implementation hooks for Python Analytics Engine integration
    return _service.getLandListings();
  }

  @override
  Future<List<LandPlot>> getLandListings() => _service.getLandListings(); // Returns canonical type

  @override
  Future<List<String>> getFavoriteIds() async => <String>[]; // Logic for persistent favorites

  @override
  Future<void> addToFavorites(String id) async {} // Logic for adding to local/remote storage

  @override
  Future<void> removeFromFavorites(String id) async {} // Logic for removing from storage
}
