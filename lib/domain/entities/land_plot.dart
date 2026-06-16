import 'package:flutter/foundation.dart';
import 'package:gulflands/core/utils/land_plot_validator.dart' as validator;

// Enum to represent the countries in the Gulf region.
// Using an enum ensures data integrity and prevents typos.
enum Country { saudiArabia, uae, qatar, bahrain, oman, kuwait }

Country countryFromString(String value) {
  return Country.values.firstWhere(
    (Country country) => country.name == value,
    orElse: () => Country.saudiArabia,
  );
}

// A model class representing a single plot of land for sale.
// This structure is the definitive contract for all land data in the app.
@immutable
class LandPlot {
  const LandPlot({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.area,
    required this.country,
    required this.location,
    required this.imageUrls,
    required this.createdAt,
    this.isFeatured = false,
    this.updatedAt,
  });

  factory LandPlot.fromJson(Map<String, dynamic> json) {
    // Validate data against contract
    if (!validator.LandPlotValidator.validate(json)) {
      final List<String> errors = validator.LandPlotValidator.getErrors(json);
      throw FormatException('Invalid land plot data: ${errors.join(', ')}');
    }

    return LandPlot(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      area: (json['area'] as num).toDouble(),
      country: countryFromString(json['country'] as String),
      location: json['location'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
    );
  }
  final String id;
  final String title;
  final String description;
  final double price;
  final double area; // Area in square meters (m^2).
  final Country country;
  final String location; // e.g., 'Riyadh, Al-Malqa District'
  final List<String> imageUrls;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'country': country.name,
      'location': location,
      'imageUrls': imageUrls,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  double get pricePerSquareMeter => area == 0 ? 0 : price / area;

  // Computed properties for better UI experience
  String get formattedPrice {
    return 'SAR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String get formattedArea {
    return area >= 10000
        ? '${(area / 10000).toStringAsFixed(1)} hectares'
        : '${area.toStringAsFixed(0)} m²';
  }

  // A helper to get a display-friendly string for the country.
  String get countryDisplay {
    switch (country) {
      case Country.saudiArabia:
        return 'Saudi Arabia';
      case Country.uae:
        return 'United Arab Emirates';
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

  LandPlot copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? area,
    Country? country,
    String? location,
    List<String>? imageUrls,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LandPlot(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      area: area ?? this.area,
      country: country ?? this.country,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandPlot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LandPlot(id: $id, title: $title, country: $country, price: $price)';
  }
}
