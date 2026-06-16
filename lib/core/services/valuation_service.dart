import 'dart:convert';

import 'package:gulflands/core/config/app_config.dart';
import 'package:gulflands/core/network/api_client.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/services/valuation_client.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ValuationResult {
  const ValuationResult({
    required this.estimatedValue,
    required this.currency,
    required this.source,
    this.formula,
  });

  final double estimatedValue;
  final String currency;
  final String source;
  final String? formula;
}

/// Valuation with server authority and deterministic local fallback.
class ValuationService {
  ValuationService({http.Client? client, Logger? logger})
    : _client = client ?? http.Client(),
      _logger = logger ?? Logger();

  final http.Client _client;
  final Logger _logger;

  Future<ValuationResult> estimate({
    required Country country,
    required double areaSqm,
    required double coastalDistanceKm,
    required String zoning,
    String city = 'default',
  }) async {
    try {
      final Uri uri = Uri.parse(
        '${AppConfig.pythonApiUrl}/v1/valuation/estimate',
      );
      final http.Response response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(<String, Object>{
              'country': country.name,
              'area_sqm': areaSqm,
              'coastal_distance_km': coastalDistanceKm,
              'zoning': zoning,
              'city': city,
            }),
          )
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            json.decode(response.body) as Map<String, dynamic>;
        return ValuationResult(
          estimatedValue: (body['estimated_value'] as num).toDouble(),
          currency: body['currency'] as String? ?? 'USD',
          formula: body['formula'] as String?,
          source: 'backend-python',
        );
      }
    } on NetworkException {
      _logger.w('Valuation API unreachable — local fallback');
    } catch (e) {
      _logger.w('Valuation API error: $e — local fallback');
    }

    final double local = ValuationClient.calculateValuation(
      country: country,
      areaSqm: areaSqm,
      coastalDistanceKm: coastalDistanceKm,
      zoning: zoning,
      city: city,
    );

    return ValuationResult(
      estimatedValue: local,
      currency: _currencyFor(country),
      source: 'local-engine',
      formula: 'V = P_base * Area^alpha * e^(-lambda * d) * Z_z * C_r',
    );
  }

  String _currencyFor(Country country) {
    return switch (country) {
      Country.saudiArabia => 'SAR',
      Country.uae => 'AED',
      Country.qatar => 'QAR',
      Country.kuwait => 'KWD',
      Country.bahrain => 'BHD',
      Country.oman => 'OMR',
    };
  }
}
