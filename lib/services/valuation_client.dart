import 'dart:math' as math;
import 'package:gulflands/models/land_plot.dart';

class ValuationClient {
  // Constant configuration synchronized across all platforms via parity audits
  static const Map<String, double> baseRates = <String, double>{
    'saudiArabia': 1200.0,
    'uae': 2500.0,
    'qatar': 2200.0,
    'kuwait': 180.0,
    'bahrain': 280.0,
    'oman': 90.0,
  };

  static const double areaExponent = 0.88;
  static const double coastalDecay = 0.05;

  static const Map<String, double> zoningMultipliers = <String, double>{
    'commercial': 1.45,
    'mixed-use': 1.30,
    'residential': 1.00,
    'tourism': 1.25,
    'industrial': 0.85,
    'agricultural': 0.50,
  };

  static const Map<String, double> regionalMultipliers = <String, double>{
    'Riyadh': 1.25,
    'Jeddah': 1.10,
    'NEOM Zone': 1.50,
    'Dubai': 1.40,
    'Abu Dhabi': 1.30,
    'Doha': 1.20,
    'Manama': 1.05,
    'Muscat': 1.00,
  };

  /// Compute local land valuation with strict mathematical alignment to backends.
  static double calculateValuation({
    required Country country,
    required double areaSqm,
    required double coastalDistanceKm,
    required String zoning,
    String city = 'default',
  }) {
    final double baseRate = baseRates[country.name] ?? 1000.0;

    final num areaFactor = math.pow(areaSqm, areaExponent);

    final double coastalFactor = math.exp(
      -coastalDecay * math.max(0.0, coastalDistanceKm),
    );

    final double zoningFactor = zoningMultipliers[zoning.toLowerCase()] ?? 1.00;

    final double regionalFactor = regionalMultipliers[city] ?? 1.00;

    final double rawVal =
        baseRate * areaFactor * coastalFactor * zoningFactor * regionalFactor;

    // Round to 2 decimal places to match backend specifications
    return double.parse(rawVal.toStringAsFixed(2));
  }
}
