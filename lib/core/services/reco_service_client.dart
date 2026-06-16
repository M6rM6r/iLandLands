import 'dart:convert';

import 'package:gulflands/core/config/app_config.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class RecoServiceClient {
  RecoServiceClient({http.Client? client, Logger? logger})
    : _client = client ?? http.Client(),
      _logger = logger ?? Logger();

  final http.Client _client;
  final Logger _logger;

  /// Returns listing IDs ranked by reco-service; empty on failure.
  Future<List<String>> fetchRecommendationIds({
    required String userId,
    required List<LandPlot> candidates,
    List<String> favoriteIds = const <String>[],
    int topN = 10,
  }) async {
    if (candidates.isEmpty) return <String>[];

    try {
      final Uri uri = Uri.parse(
        '${AppConfig.recoServiceUrl}/v1/recommendations',
      );
      final http.Response response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(<String, Object>{
              'profile': <String, Object>{
                'user_id': userId,
                'preferences': _derivePreferences(candidates, favoriteIds),
              },
              'interactions': favoriteIds
                  .map(
                    (String id) => <String, String>{
                      'listing_id': id,
                      'action': 'favorite',
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  )
                  .toList(),
              'top_n': topN,
            }),
          )
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode != 200) return <String>[];

      final List<dynamic> body = json.decode(response.body) as List<dynamic>;
      return body
          .map((e) => (e as Map<String, dynamic>)['listing_id'] as String)
          .toList();
    } catch (e) {
      _logger.w('Reco service unavailable: $e');
      return <String>[];
    }
  }

  Map<String, dynamic> _derivePreferences(
    List<LandPlot> candidates,
    List<String> favoriteIds,
  ) {
    final List<LandPlot> favorites = candidates
        .where((LandPlot p) => favoriteIds.contains(p.id))
        .toList();
    if (favorites.isEmpty) {
      return <String, dynamic>{'region': 'gulf'};
    }
    final double avgPrice =
        favorites
            .map((LandPlot p) => p.price)
            .reduce((double a, double b) => a + b) /
        favorites.length;
    return <String, dynamic>{
      'country': favorites.first.country.name,
      'price_min': avgPrice * 0.7,
      'price_max': avgPrice * 1.3,
    };
  }
}
