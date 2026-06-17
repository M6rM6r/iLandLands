// Development stub — delegates to the mock LandService.
// Production uses LandRepositoryImpl from services/land_repository.dart (Firebase-backed).
import 'package:gulflands/domain/repositories/land_repository.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';
import 'package:gulflands/services/land_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LandRepository)
class LandRepositoryImpl implements LandRepository {
  LandRepositoryImpl(this._service);

  final LandService _service;
  final Set<String> _favorites = <String>{};

  @override
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh = false,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    List<LandPlot> plots = await _service.getLandListings();

    if (country != null) {
      plots = plots.where((LandPlot p) => p.country == country).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final String q = searchQuery.toLowerCase();
      plots = plots.where((LandPlot p) {
        return p.title.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    if (sortBy != null) {
      switch (sortBy) {
        case SortOption.priceAsc:
          plots.sort((LandPlot a, LandPlot b) => a.price.compareTo(b.price));
        case SortOption.priceDesc:
          plots.sort((LandPlot a, LandPlot b) => b.price.compareTo(a.price));
        case SortOption.areaAsc:
          plots.sort((LandPlot a, LandPlot b) => a.area.compareTo(b.area));
        case SortOption.areaDesc:
          plots.sort((LandPlot a, LandPlot b) => b.area.compareTo(a.area));
        case SortOption.oldest:
          plots.sort(
            (LandPlot a, LandPlot b) => a.createdAt.compareTo(b.createdAt),
          );
        default:
          plots.sort(
            (LandPlot a, LandPlot b) => b.createdAt.compareTo(a.createdAt),
          );
      }
    }

    return plots;
  }

  @override
  Future<LandPlot?> getLandPlotById(String id) async {
    final List<LandPlot> plots = await _service.getLandListings();
    try {
      return plots.firstWhere((LandPlot p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LandPlot>> getFeaturedListings() async {
    final List<LandPlot> plots = await _service.getLandListings();
    return plots.where((LandPlot p) => p.isFeatured).toList();
  }

  @override
  Future<List<String>> getFavoriteIds() async => _favorites.toList();

  @override
  Future<void> addToFavorites(String landId) async => _favorites.add(landId);

  @override
  Future<void> removeFromFavorites(String landId) async =>
      _favorites.remove(landId);
}
