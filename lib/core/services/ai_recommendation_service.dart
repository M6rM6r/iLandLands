import 'dart:math';

import 'package:gulflands/core/services/reco_service_client.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

abstract class AIRecommendationService {
  Future<List<LandPlot>> getRecommendations(
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
    List<String> viewedCategories,
    Map<String, dynamic> userProfile,
  );

  Future<double> calculateSimilarity(LandPlot plot1, LandPlot plot2);
  Future<List<LandPlot>> getSimilarListings(
    LandPlot targetPlot,
    List<LandPlot> candidates,
  );
  Future<Map<String, dynamic>> analyzeUserPreferences(
    List<LandPlot> userHistory,
  );
  Future<List<LandPlot>> getTrendingListings();
}

@LazySingleton(as: AIRecommendationService)
class AIRecommendationServiceImpl implements AIRecommendationService {
  AIRecommendationServiceImpl(this.logger, {RecoServiceClient? recoClient})
    : _recoClient = recoClient ?? RecoServiceClient(logger: logger);
  final Logger logger;
  final RecoServiceClient _recoClient;

  // Weight factors for different recommendation algorithms
  static const double _collaborativeWeight = 0.4;
  static const double _contentBasedWeight = 0.3;
  static const double _trendingWeight = 0.2;
  static const double _personalizedWeight = 0.1;

  // Location desirability scores
  static const Map<String, double> _locationScores = <String, double>{
    'saudiArabia': 0.8,
    'uae': 0.95,
    'qatar': 0.85,
    'bahrain': 0.75,
    'oman': 0.7,
    'kuwait': 0.8,
  };

  // Price range preferences (reserved for future personalised scoring)
  // ignore: unused_field
  static const Map<String, double> _priceRangeScores = <String, double>{
    'budget': 0.6, // < 1M SAR
    'mid_range': 0.8, // 1-5M SAR
    'premium': 0.9, // 5-10M SAR
    'luxury': 0.95, // > 10M SAR
  };

  @override
  Future<List<LandPlot>> getRecommendations(
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
    List<String> viewedCategories,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      logger.d('Generating AI recommendations for user');

      // Analyze user preferences
      final Map<String, dynamic> preferences = await analyzeUserPreferences(
        userHistory,
      );

      // Get trending listings
      final List<LandPlot> trendingListings = await getTrendingListings();

      // Calculate recommendation scores
      final List<LandPlot> recommendations = <LandPlot>[];

      // Combine different recommendation strategies
      for (final LandPlot plot in trendingListings) {
        // Consider all available plots, not just trending
        // Skip already viewed plots
        if (userHistory.any((LandPlot p) => p.id == plot.id)) {
          continue; // Skip already viewed
        }

        final double collaborativeScore = _calculateCollaborativeScore(
          plot,
          userHistory,
          userFavorites,
        );
        final double contentBasedScore = _calculateContentBasedScore(
          plot,
          preferences,
        );
        final double trendingScore = _calculateTrendingScore(plot);
        final double personalizedScore = _calculatePersonalizedScore(
          plot,
          userProfile,
        );

        // Weighted combination
        final double finalScore =
            (collaborativeScore * _collaborativeWeight) +
            (contentBasedScore * _contentBasedWeight) +
            (trendingScore * _trendingWeight) +
            (personalizedScore * _personalizedWeight);

        if (finalScore > 0.6) {
          // Threshold for recommendation
          recommendations.add(plot);
        }
      }

      // Sort by recommendation score
      recommendations.sort((LandPlot a, LandPlot b) {
        final double scoreA = _calculateFinalScore(
          a,
          userHistory,
          userFavorites,
          userProfile,
          preferences,
        );
        final double scoreB = _calculateFinalScore(
          b,
          userHistory,
          userFavorites,
          userProfile,
          preferences,
        );
        return scoreB.compareTo(scoreA);
      });

      logger.d('Generated ${recommendations.length} recommendations');
      return recommendations.take(10).toList();
    } catch (e) {
      logger.e('Failed to generate recommendations: $e');
      return <LandPlot>[];
    }
  }

  @override
  Future<double> calculateSimilarity(LandPlot plot1, LandPlot plot2) async {
    try {
      // Calculate similarity based on multiple factors
      double similarity = 0.0;
      int factors = 0;

      // Location similarity
      if (plot1.country == plot2.country) {
        similarity += 0.3;
      }
      factors++;

      // Price range similarity
      final double priceRatio1 = plot1.price / plot1.area;
      final double priceRatio2 = plot2.price / plot2.area;
      final double maxRatio = max(priceRatio1, priceRatio2);
      final double priceSimilarity = maxRatio == 0
          ? 1.0
          : 1.0 - (priceRatio1 - priceRatio2).abs() / maxRatio;
      similarity += priceSimilarity * 0.25;
      factors++;

      // Area similarity
      final double areaRatio =
          min(plot1.area, plot2.area) / max(plot1.area, plot2.area);
      similarity += areaRatio * 0.2;
      factors++;

      // Featured status similarity
      if (plot1.isFeatured == plot2.isFeatured) {
        similarity += 0.15;
      }
      factors++;

      // Text similarity (title and description)
      final double textSimilarity = _calculateTextSimilarity(
        '${plot1.title} ${plot1.description}',
        '${plot2.title} ${plot2.description}',
      );
      similarity += textSimilarity * 0.1;
      factors++;

      return similarity / factors.toDouble();
    } catch (e) {
      logger.e('Failed to calculate similarity: $e');
      return 0.0;
    }
  }

  @override
  Future<List<LandPlot>> getSimilarListings(
    LandPlot targetPlot,
    List<LandPlot> candidates,
  ) async {
    try {
      final Map<String, double> similarities = <String, double>{};

      for (final LandPlot candidate in candidates) {
        if (candidate.id == targetPlot.id) continue;

        final double similarity = await calculateSimilarity(
          targetPlot,
          candidate,
        );
        similarities[candidate.id] = similarity;
      }

      // Sort by similarity
      final List<LandPlot> sortedCandidates = candidates
          .where((LandPlot c) => similarities.containsKey(c.id))
          .toList();
      sortedCandidates.sort(
        (LandPlot a, LandPlot b) =>
            similarities[b.id]!.compareTo(similarities[a.id]!),
      );

      return sortedCandidates.take(5).toList();
    } catch (e) {
      logger.e('Failed to get similar listings: $e');
      return <LandPlot>[];
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeUserPreferences(
    List<LandPlot> userHistory,
  ) async {
    try {
      if (userHistory.isEmpty) {
        return <String, dynamic>{
          'preferredCountries': <String>[],
          'priceRange': 'mid_range',
          'avgArea': 0.0,
          'preferredLocations': <String>[],
          'features': <String>[],
        };
      }

      // Analyze country preferences
      final Map<String, int> countryCounts = <String, int>{};
      for (final LandPlot plot in userHistory) {
        countryCounts[plot.country.name] =
            (countryCounts[plot.country.name] ?? 0) + 1;
      }

      final List<String> preferredCountries = countryCounts.entries
          .where((MapEntry<String, int> e) => e.value >= 2)
          .map((MapEntry<String, int> e) => e.key)
          .toList();

      // Analyze price preferences
      final List<double> prices = userHistory
          .map((LandPlot p) => p.price)
          .toList();
      final double avgPrice =
          prices.reduce((double a, double b) => a + b) / prices.length;

      String priceRange;
      if (avgPrice < 1000000) {
        priceRange = 'budget';
      } else if (avgPrice < 5000000) {
        priceRange = 'mid_range';
      } else if (avgPrice < 10000000) {
        priceRange = 'premium';
      } else {
        priceRange = 'luxury';
      }

      // Analyze area preferences
      final List<double> areas = userHistory
          .map((LandPlot p) => p.area)
          .toList();
      final double avgArea =
          areas.reduce((double a, double b) => a + b) / areas.length;

      // Analyze location preferences
      final Map<String, int> locationCounts = <String, int>{};
      for (final LandPlot plot in userHistory) {
        final String location = plot.location.split(',').first.trim();
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }

      final List<String> preferredLocations = locationCounts.entries
          .where((MapEntry<String, int> e) => e.value >= 2)
          .map((MapEntry<String, int> e) => e.key)
          .toList();

      // Analyze features
      final Set<String> features = <String>{};
      if (userHistory.any((LandPlot p) => p.isFeatured)) {
        features.add('featured');
      }

      if (avgArea > 10000) {
        features.add('large_area');
      }

      if (avgPrice > 5000000) {
        features.add('premium');
      }

      return <String, dynamic>{
        'preferredCountries': preferredCountries,
        'priceRange': priceRange,
        'avgPrice': avgPrice,
        'avgArea': avgArea,
        'preferredLocations': preferredLocations,
        'features': features.toList(),
      };
    } catch (e) {
      logger.e('Failed to analyze user preferences: $e');
      return <String, dynamic>{};
    }
  }

  @override
  Future<List<LandPlot>> getTrendingListings() async {
    try {
      logger.d('Fetching recommendations from reco-service');
      final List<String> ids = await _recoClient.fetchRecommendationIds(
        userId: 'anonymous',
        candidates: const <LandPlot>[],
        topN: 20,
      );
      if (ids.isEmpty) return <LandPlot>[];
      logger.d('Reco service returned ${ids.length} ids');
      return <LandPlot>[];
    } catch (e) {
      logger.e('Failed to get trending listings: $e');
      return <LandPlot>[];
    }
  }

  double _calculateCollaborativeScore(
    LandPlot plot,
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
  ) {
    double score = 0.0;

    // Check if similar users liked this plot
    for (final LandPlot favorite in userFavorites) {
      final double similarity = _plotSimilarity(plot, favorite);
      score += similarity * 0.5;
    }

    // Check viewing patterns
    for (final LandPlot viewed in userHistory) {
      final double similarity = _plotSimilarity(plot, viewed);
      score += similarity * 0.3;
    }

    return min(score, 1);
  }

  double _calculateContentBasedScore(
    LandPlot plot,
    Map<String, dynamic> preferences,
  ) {
    double score = 0.0;

    // Country preference
    final List<String> preferredCountries =
        preferences['preferredCountries'] as List<String>? ?? <String>[];
    if (preferredCountries.contains(plot.country.name)) {
      score += 0.3;
    }

    // Price range preference
    final String priceRange =
        preferences['priceRange'] as String? ?? 'mid_range';
    score += _getPriceScore(plot.price, priceRange) * 0.25;

    // Area preference
    final double avgArea = preferences['avgArea'] as double? ?? 0.0;
    if (avgArea > 0) {
      final double areaSimilarity = 1.0 - (plot.area - avgArea).abs() / avgArea;
      score += areaSimilarity * 0.2;
    }

    // Location preference
    final List<String> preferredLocations =
        preferences['preferredLocations'] as List<String>? ?? <String>[];
    final String plotLocation = plot.location.split(',').first.trim();
    if (preferredLocations.contains(plotLocation)) {
      score += 0.15;
    }

    // Features preference
    final List<String> features =
        preferences['features'] as List<String>? ?? <String>[];
    if (plot.isFeatured && features.contains('featured')) {
      score += 0.1;
    }

    return min(score, 1);
  }

  double _calculateTrendingScore(LandPlot plot) {
    // In a real implementation, this would use actual trending data
    // For now, use static factors

    double score = 0.0;

    // Featured listings get higher trending score
    if (plot.isFeatured) {
      score += 0.3;
    }

    // Recent listings get higher trending score
    final int daysSinceCreation = DateTime.now()
        .difference(plot.createdAt)
        .inDays;
    if (daysSinceCreation < 7) {
      score += 0.2;
    } else if (daysSinceCreation < 30) {
      score += 0.1;
    }

    // Popular locations get higher trending score
    score += _locationScores[plot.country.name] ?? 0.5 * 0.3;

    // Price efficiency
    final double pricePerSqm = plot.price / plot.area;
    if (pricePerSqm < 1000) {
      score += 0.2; // Good value
    } else if (pricePerSqm < 5000) {
      score += 0.1; // Reasonable value
    }

    return min(score, 1);
  }

  double _calculatePersonalizedScore(
    LandPlot plot,
    Map<String, dynamic> userProfile,
  ) {
    double score = 0.0;

    // User-specific factors
    final String deviceType =
        userProfile['device_type'] as String? ?? 'unknown';
    final String location = userProfile['location'] as String? ?? 'unknown';

    // Mobile users might prefer different features
    if (deviceType == 'mobile') {
      // Prefer listings with better mobile experience
      if (plot.imageUrls.isNotEmpty) {
        score += 0.1;
      }
    }

    // Location-based personalization
    if (location != 'unknown' && _isNearby(plot, location)) {
      score += 0.2;
    }

    // Time-based personalization
    final int hour = DateTime.now().hour;
    if (hour >= 18 && hour <= 22) {
      // Evening browsing
      // Prefer premium listings in the evening
      if (plot.price > 5000000) {
        score += 0.1;
      }
    }

    return min(score, 1);
  }

  double _calculateFinalScore(
    LandPlot plot,
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
    Map<String, dynamic> userProfile,
    Map<String, dynamic> preferences,
  ) {
    final double collaborativeScore = _calculateCollaborativeScore(
      plot,
      userHistory,
      userFavorites,
    );
    final double contentBasedScore = _calculateContentBasedScore(
      plot,
      preferences,
    );
    final double trendingScore = _calculateTrendingScore(plot);
    final double personalizedScore = _calculatePersonalizedScore(
      plot,
      userProfile,
    );

    return (collaborativeScore * _collaborativeWeight) +
        (contentBasedScore * _contentBasedWeight) +
        (trendingScore * _trendingWeight) +
        (personalizedScore * _personalizedWeight);
  }

  double _plotSimilarity(LandPlot plot1, LandPlot plot2) {
    double similarity = 0.0;

    // Country similarity
    if (plot1.country == plot2.country) {
      similarity += 0.3;
    }

    // Price similarity
    final double priceRatio =
        min(plot1.price, plot2.price) / max(plot1.price, plot2.price);
    similarity += priceRatio * 0.3;

    // Area similarity
    final double areaRatio =
        min(plot1.area, plot2.area) / max(plot1.area, plot2.area);
    similarity += areaRatio * 0.2;

    // Featured status
    if (plot1.isFeatured == plot2.isFeatured) {
      similarity += 0.2;
    }

    return similarity;
  }

  double _getPriceScore(double price, String priceRange) {
    switch (priceRange) {
      case 'budget':
        return price < 1000000
            ? 1.0
            : max(0, 1.0 - (price - 1000000) / 4000000);
      case 'mid_range':
        return price >= 1000000 && price < 5000000
            ? 1.0
            : price < 1000000
            ? 0.7
            : max(0, 1.0 - (price - 5000000) / 5000000);
      case 'premium':
        return price >= 5000000 && price < 10000000
            ? 1.0
            : price < 5000000
            ? 0.6
            : max(0, 1.0 - (price - 10000000) / 10000000);
      case 'luxury':
        return price >= 10000000 ? 1.0 : price / 10000000;
      default:
        return 0.5;
    }
  }

  double _calculateTextSimilarity(String text1, String text2) {
    final List<String> words1 = text1.toLowerCase().split(' ');
    final List<String> words2 = text2.toLowerCase().split(' ');

    final Set<String> set1 = words1.where((String w) => w.length > 2).toSet();
    final Set<String> set2 = words2.where((String w) => w.length > 2).toSet();
    if (set1.isEmpty && set2.isEmpty) return 1.0;
    final int intersection = set1.intersection(set2).length;
    final int union = set1.union(set2).length;
    return intersection / union;
  }

  bool _isNearby(LandPlot plot, String userLocation) {
    // Simplified proximity check
    // In a real implementation, this would use actual geolocation
    return plot.location.toLowerCase().contains(userLocation.toLowerCase());
  }
}
