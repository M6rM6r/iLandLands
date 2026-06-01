import 'dart:math';

import 'package:gulflands/models/land_plot.dart';
import 'package:logger/logger.dart';

abstract class AIRecommendationService {
  Future<List<LandPlot>> getRecommendations(
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
    List<String> viewedCategories,
    Map<String, dynamic> userProfile,
  );
  
  Future<double> calculateSimilarity(LandPlot plot1, LandPlot plot2);
  Future<List<LandPlot>> getSimilarListings(LandPlot targetPlot, List<LandPlot> candidates);
  Future<Map<String, dynamic>> analyzeUserPreferences(List<LandPlot> userHistory);
  Future<List<LandPlot>> getTrendingListings();
}

class AIRecommendationServiceImpl implements AIRecommendationService {

  AIRecommendationServiceImpl(this.logger);
  final Logger logger;
  
  // Weight factors for different recommendation algorithms
  static const double _collaborativeWeight = 0.4;
  static const double _contentBasedWeight = 0.3;
  static const double _trendingWeight = 0.2;
  static const double _personalizedWeight = 0.1;
  
  // Location desirability scores
  static const Map<String, double> _locationScores = {
    'saudiArabia': 0.8,
    'uae': 0.95,
    'qatar': 0.85,
    'bahrain': 0.75,
    'oman': 0.7,
    'kuwait': 0.8,
  };
  
  // Price range preferences (reserved for future personalised scoring)
  // ignore: unused_field
  static const Map<String, double> _priceRangeScores = {
    'budget': 0.6,      // < 1M SAR
    'mid_range': 0.8,   // 1-5M SAR
    'premium': 0.9,     // 5-10M SAR
    'luxury': 0.95,     // > 10M SAR
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
      final preferences = await analyzeUserPreferences(userHistory);
      
      // Get trending listings
      final trendingListings = await getTrendingListings();
      
      // Calculate recommendation scores
      final recommendations = <LandPlot>[];
      
      // Combine different recommendation strategies
      for (final plot in trendingListings) {
        if (userHistory.any((p) => p.id == plot.id)) continue; // Skip already viewed
        
        final collaborativeScore = _calculateCollaborativeScore(plot, userHistory, userFavorites);
        final contentBasedScore = _calculateContentBasedScore(plot, preferences);
        final trendingScore = _calculateTrendingScore(plot);
        final personalizedScore = _calculatePersonalizedScore(plot, userProfile);
        
        // Weighted combination
        final finalScore = 
            (collaborativeScore * _collaborativeWeight) +
            (contentBasedScore * _contentBasedWeight) +
            (trendingScore * _trendingWeight) +
            (personalizedScore * _personalizedWeight);
        
        if (finalScore > 0.6) { // Threshold for recommendation
          recommendations.add(plot);
        }
      }
      
      // Sort by recommendation score
      recommendations.sort((a, b) {
        final scoreA = _calculateFinalScore(a, userHistory, userFavorites, userProfile);
        final scoreB = _calculateFinalScore(b, userHistory, userFavorites, userProfile);
        return scoreB.compareTo(scoreA);
      });
      
      logger.d('Generated ${recommendations.length} recommendations');
      return recommendations.take(10).toList();
      
    } catch (e) {
      logger.e('Failed to generate recommendations: $e');
      return [];
    }
  }

  @override
  Future<double> calculateSimilarity(LandPlot plot1, LandPlot plot2) async {
    try {
      // Calculate similarity based on multiple factors
      var similarity = 0.0;
      var factors = 0;
      
      // Location similarity
      if (plot1.country == plot2.country) {
        similarity += 0.3;
      }
      factors++;
      
      // Price range similarity
      final priceRatio1 = plot1.price / plot1.area;
      final priceRatio2 = plot2.price / plot2.area;
      final priceSimilarity = 1.0 - (priceRatio1 - priceRatio2).abs() / max(priceRatio1, priceRatio2);
      similarity += priceSimilarity * 0.25;
      factors++;
      
      // Area similarity
      final areaRatio = min(plot1.area, plot2.area) / max(plot1.area, plot2.area);
      similarity += areaRatio * 0.2;
      factors++;
      
      // Featured status similarity
      if (plot1.isFeatured == plot2.isFeatured) {
        similarity += 0.15;
      }
      factors++;
      
      // Text similarity (title and description)
      final textSimilarity = _calculateTextSimilarity(
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
  Future<List<LandPlot>> getSimilarListings(LandPlot targetPlot, List<LandPlot> candidates) async {
    try {
      final similarities = <String, double>{};
      
      for (final candidate in candidates) {
        if (candidate.id == targetPlot.id) continue;
        
        final similarity = await calculateSimilarity(targetPlot, candidate);
        similarities[candidate.id] = similarity;
      }
      
      // Sort by similarity
      final sortedCandidates = candidates.where((c) => similarities.containsKey(c.id)).toList();
      sortedCandidates.sort((a, b) => similarities[b.id]!.compareTo(similarities[a.id]!));
      
      return sortedCandidates.take(5).toList();
      
    } catch (e) {
      logger.e('Failed to get similar listings: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeUserPreferences(List<LandPlot> userHistory) async {
    try {
      if (userHistory.isEmpty) {
        return {
          'preferredCountries': <String>[],
          'priceRange': 'mid_range',
          'avgArea': 0.0,
          'preferredLocations': <String>[],
          'features': <String>[],
        };
      }
      
      // Analyze country preferences
      final countryCounts = <String, int>{};
      for (final plot in userHistory) {
        countryCounts[plot.country.name] = (countryCounts[plot.country.name] ?? 0) + 1;
      }
      
      final preferredCountries = countryCounts.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .toList();
      
      // Analyze price preferences
      final prices = userHistory.map((p) => p.price).toList();
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
      
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
      final areas = userHistory.map((p) => p.area).toList();
      final avgArea = areas.reduce((a, b) => a + b) / areas.length;
      
      // Analyze location preferences
      final locationCounts = <String, int>{};
      for (final plot in userHistory) {
        final location = plot.location.split(',').first.trim();
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }
      
      final preferredLocations = locationCounts.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .toList();
      
      // Analyze features
      final features = <String>{};
      if (userHistory.any((p) => p.isFeatured)) {
        features.add('featured');
      }
      
      if (avgArea > 10000) {
        features.add('large_area');
      }
      
      if (avgPrice > 5000000) {
        features.add('premium');
      }
      
      return {
        'preferredCountries': preferredCountries,
        'priceRange': priceRange,
        'avgPrice': avgPrice,
        'avgArea': avgArea,
        'preferredLocations': preferredLocations,
        'features': features.toList(),
      };
      
    } catch (e) {
      logger.e('Failed to analyze user preferences: $e');
      return {};
    }
  }

  @override
  Future<List<LandPlot>> getTrendingListings() async {
    try {
      // In a real implementation, this would fetch from analytics service
      // For now, return mock trending data
      logger.d('Fetching trending listings');
      
      // This would be replaced with actual analytics data
      return [];
      
    } catch (e) {
      logger.e('Failed to get trending listings: $e');
      return [];
    }
  }

  double _calculateCollaborativeScore(
    LandPlot plot,
    List<LandPlot> userHistory,
    List<LandPlot> userFavorites,
  ) {
    var score = 0.0;
    
    // Check if similar users liked this plot
    for (final favorite in userFavorites) {
      final similarity = _plotSimilarity(plot, favorite);
      score += similarity * 0.5;
    }
    
    // Check viewing patterns
    for (final viewed in userHistory) {
      final similarity = _plotSimilarity(plot, viewed);
      score += similarity * 0.3;
    }
    
    return min(score, 1);
  }

  double _calculateContentBasedScore(LandPlot plot, Map<String, dynamic> preferences) {
    var score = 0.0;
    
    // Country preference
    final preferredCountries = preferences['preferredCountries'] as List<String>? ?? [];
    if (preferredCountries.contains(plot.country.name)) {
      score += 0.3;
    }
    
    // Price range preference
    final priceRange = preferences['priceRange'] as String? ?? 'mid_range';
    score += _getPriceScore(plot.price, priceRange) * 0.25;
    
    // Area preference
    final avgArea = preferences['avgArea'] as double? ?? 0.0;
    if (avgArea > 0) {
      final areaSimilarity = 1.0 - (plot.area - avgArea).abs() / avgArea;
      score += areaSimilarity * 0.2;
    }
    
    // Location preference
    final preferredLocations = preferences['preferredLocations'] as List<String>? ?? [];
    final plotLocation = plot.location.split(',').first.trim();
    if (preferredLocations.contains(plotLocation)) {
      score += 0.15;
    }
    
    // Features preference
    final features = preferences['features'] as List<String>? ?? [];
    if (plot.isFeatured && features.contains('featured')) {
      score += 0.1;
    }
    
    return min(score, 1);
  }

  double _calculateTrendingScore(LandPlot plot) {
    // In a real implementation, this would use actual trending data
    // For now, use static factors
    
    var score = 0.0;
    
    // Featured listings get higher trending score
    if (plot.isFeatured) {
      score += 0.3;
    }
    
    // Recent listings get higher trending score
    final daysSinceCreation = DateTime.now().difference(plot.createdAt).inDays;
    if (daysSinceCreation < 7) {
      score += 0.2;
    } else if (daysSinceCreation < 30) {
      score += 0.1;
    }
    
    // Popular locations get higher trending score
    score += _locationScores[plot.country.name] ?? 0.5 * 0.3;
    
    // Price efficiency
    final pricePerSqm = plot.price / plot.area;
    if (pricePerSqm < 1000) {
      score += 0.2; // Good value
    } else if (pricePerSqm < 5000) {
      score += 0.1; // Reasonable value
    }
    
    return min(score, 1);
  }

  double _calculatePersonalizedScore(LandPlot plot, Map<String, dynamic> userProfile) {
    var score = 0.0;
    
    // User-specific factors
    final deviceType = userProfile['device_type'] as String? ?? 'unknown';
    final location = userProfile['location'] as String? ?? 'unknown';
    
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
    final hour = DateTime.now().hour;
    if (hour >= 18 && hour <= 22) { // Evening browsing
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
  ) {
    final collaborativeScore = _calculateCollaborativeScore(plot, userHistory, userFavorites);
    final contentBasedScore = _calculateContentBasedScore(plot, {});
    final trendingScore = _calculateTrendingScore(plot);
    final personalizedScore = _calculatePersonalizedScore(plot, userProfile);
    
    return (collaborativeScore * _collaborativeWeight) +
           (contentBasedScore * _contentBasedWeight) +
           (trendingScore * _trendingWeight) +
           (personalizedScore * _personalizedWeight);
  }

  double _plotSimilarity(LandPlot plot1, LandPlot plot2) {
    var similarity = 0.0;
    
    // Country similarity
    if (plot1.country == plot2.country) {
      similarity += 0.3;
    }
    
    // Price similarity
    final priceRatio = min(plot1.price, plot2.price) / max(plot1.price, plot2.price);
    similarity += priceRatio * 0.3;
    
    // Area similarity
    final areaRatio = min(plot1.area, plot2.area) / max(plot1.area, plot2.area);
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
        return price < 1000000 ? 1.0 : max(0, 1.0 - (price - 1000000) / 4000000);
      case 'mid_range':
        return price >= 1000000 && price < 5000000 ? 1.0 : 
               price < 1000000 ? 0.7 : max(0, 1.0 - (price - 5000000) / 5000000);
      case 'premium':
        return price >= 5000000 && price < 10000000 ? 1.0 :
               price < 5000000 ? 0.6 : max(0, 1.0 - (price - 10000000) / 10000000);
      case 'luxury':
        return price >= 10000000 ? 1.0 : price / 10000000;
      default:
        return 0.5;
    }
  }

  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');
    
    final intersection = words1.where(words2.contains).length;
    final union = words1.toSet()..addAll(words2);
    
    return intersection / union.length;
  }

  bool _isNearby(LandPlot plot, String userLocation) {
    // Simplified proximity check
    // In a real implementation, this would use actual geolocation
    return plot.location.toLowerCase().contains(userLocation.toLowerCase());
  }
}
