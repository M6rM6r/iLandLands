import 'package:gulflands/core/services/ranking_service.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/scored_land_plot.dart';
import 'package:gulflands/services/land_repository.dart';

class SearchAndRankListings {
  SearchAndRankListings(this.repository, this.rankingService);
  final LandRepository repository;
  final RankingService rankingService;

  Future<List<ScoredLandPlot>> call(
    String query, {
    Country? country,
    List<String>? favoriteIds,
  }) async {
    final List<LandPlot> listings = await repository.getLandListings();
    return rankingService.rankListings(
      listings,
      query,
      favoriteIds: favoriteIds ?? <String>[],
    );
  }
}
