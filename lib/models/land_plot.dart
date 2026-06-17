import 'package:flutter/foundation.dart';

enum Country { saudiArabia, uae, qatar, bahrain, oman, kuwait }

@immutable
class LandPlot {
  final String id;
  final String title;
  final String description;
  final String location;
  final double price;
  final double area;
  final Country country;
  final List<String> imageUrls;
  final bool isFeatured;
  final DateTime createdAt;

  const LandPlot({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.area,
    required this.country,
    required this.imageUrls,
    this.isFeatured = false,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandPlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          price == other.price;

  @override
  int get hashCode => id.hashCode ^ price.hashCode;

  String get formattedPrice => '${(price / 1000000).toStringAsFixed(1)}M';

  String get countryDisplay {
    switch (country) {
      case Country.saudiArabia:
        return 'Saudi Arabia';
      case Country.uae:
        return 'UAE';
      case Country.qatar:
        return 'Qatar';
      case Country.bahrain:
        return 'Bahrain';
      case Country.oman:
        return 'Oman';
      case Country.kuwait:
        return 'Kuwait';
    }
  }

  String get formattedArea => '${area.toStringAsFixed(0)} sqm';
  double get pricePerSquareMeter => area > 0 ? price / area : 0;

  factory LandPlot.fromJson(Map<String, dynamic> json) {
    final dynamic rawImages = json['imageUrls'] ?? json['image_urls'];
    final dynamic rawFeatured = json['isFeatured'] ?? json['is_featured'];
    final dynamic rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return LandPlot(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      price: (json['price'] as num).toDouble(),
      area: (json['area'] as num? ?? 0).toDouble(),
      country: Country.values.firstWhere(
        (Country e) =>
            e.name.toLowerCase() == json['country']?.toString().toLowerCase(),
        orElse: () => Country.saudiArabia,
      ),
      imageUrls: (rawImages as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      isFeatured: rawFeatured as bool? ?? false,
      createdAt:
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'price': price,
    'area': area,
    'country': country.name,
    'imageUrls': imageUrls,
    'isFeatured': isFeatured,
    'createdAt': createdAt.toIso8601String(),
  };
}
