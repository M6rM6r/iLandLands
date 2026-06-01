import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/scored_land_plot.dart';

class RankingService {
  List<ScoredLandPlot> rankListings(
    List<LandPlot> listings,
    String query, {
    required List<String> favoriteIds,
  }) {
    final lowerQuery = query.toLowerCase();

    final scored = listings.map((plot) {
      var score = 0.0;
      var searchRelevance = 0.0;
      final matchReasons = <String>[];

      // Search relevance scoring
      if (plot.title.toLowerCase().contains(lowerQuery)) {
        searchRelevance += 0.4;
        matchReasons.add('Title match');
      }
      if (plot.location.toLowerCase().contains(lowerQuery)) {
        searchRelevance += 0.3;
        matchReasons.add('Location match');
      }
      if (plot.description.toLowerCase().contains(lowerQuery)) {
        searchRelevance += 0.2;
        matchReasons.add('Description match');
      }

      // Favorite boost
      if (favoriteIds.contains(plot.id)) {
        score += 0.2;
        matchReasons.add('In favorites');
      }

      // Featured boost
      if (plot.isFeatured) {
        score += 0.1;
        matchReasons.add('Featured listing');
      }

      // Final score combines relevance and boosts
      score += searchRelevance;

      return ScoredLandPlot(
        plot: plot,
        score: score,
        searchRelevance: searchRelevance,
        matchReasons: matchReasons,
      );
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }
}
