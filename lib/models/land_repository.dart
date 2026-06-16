import '../models/land_plot.dart';

abstract class LandRepository {
  Future<List<LandPlot>> getLandPlots({
    String? query,
    String? country,
    String? sortBy,
  });
  Future<void> submitLandPlot(LandPlot plot);
}
