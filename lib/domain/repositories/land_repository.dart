import 'package:gulflands/models/land_plot.dart';

abstract class LandRepository {
  Future<List<LandPlot>> getListings({
    String? country,
    double? minPrice,
    double? maxPrice,
  });
  Future<LandPlot?> getDetails(String id);
  Future<void> saveListing(LandPlot plot);
  Future<List<LandPlot>> getTrending();

  Future<List<LandPlot>> getLandListings();
  Future<List<String>> getFavoriteIds();
  Future<void> addToFavorites(String id);
  Future<void> removeFromFavorites(String id);
}
