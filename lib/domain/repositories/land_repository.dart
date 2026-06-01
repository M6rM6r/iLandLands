import 'package:gulflands/data/datasources/land_remote_datasource.dart';
import 'package:gulflands/domain/entities/land_plot.dart';

abstract class LandRepository {
  Future<List<LandPlot>> getLandListings({
    bool forceRefresh,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  });

  Future<LandPlot?> getLandPlotById(String id);

  Future<List<LandPlot>> getFeaturedListings({bool forceRefresh});

  Future<void> addToFavorites(String landId, {String userId});

  Future<void> removeFromFavorites(String landId, {String userId});

  Future<List<String>> getFavoriteIds({String userId, bool forceRefresh});
}
