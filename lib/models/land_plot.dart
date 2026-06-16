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
  String get countryDisplay => country.name;
  String get formattedArea => '${area.toStringAsFixed(0)} sqm';
  double get pricePerSquareMeter => area > 0 ? price / area : 0;

  factory LandPlot.fromJson(Map<String, dynamic> json) {
    return LandPlot(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      price: (json['price'] as num).toDouble(),
      area: (json['area'] as num? ?? 0).toDouble(),
      country: Country.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == json['country']?.toString().toLowerCase(),
        orElse: () => Country.saudiArabia,
      ),
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'price': price,
    'area': area,
    'country': country.name,
    'image_urls': imageUrls,
    'is_featured': isFeatured,
    'created_at': createdAt.toIso8601String(),
  };
}
