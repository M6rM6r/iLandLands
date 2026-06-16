import 'package:flutter/material.dart';

@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final Color brandPrimary;
  final Color surfaceElevated;
  final Color semanticError;
  final double borderRadiusSmall;
  final double borderRadiusMedium;
  final double spacingUnit;
  final TextStyle headingStyle;
  final TextStyle bodyStyle;

  const AppDesignTokens({
    required this.brandPrimary,
    required this.surfaceElevated,
    required this.semanticError,
    required this.borderRadiusSmall,
    required this.borderRadiusMedium,
    required this.spacingUnit,
    required this.headingStyle,
    required this.bodyStyle,
  });

  factory AppDesignTokens.light() => const AppDesignTokens(
    brandPrimary: Color(0xFF0052CC),
    surfaceElevated: Color(0xFFFFFFFF),
    semanticError: Color(0xFFD32F2F),
    borderRadiusSmall: 4.0,
    borderRadiusMedium: 8.0,
    spacingUnit: 8.0,
    headingStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A1A1A),
    ),
    bodyStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF4A4A4A),
    ),
  );

  factory AppDesignTokens.dark() => const AppDesignTokens(
    brandPrimary: Color(0xFF4C9AFF),
    surfaceElevated: Color(0xFF1C1C1E),
    semanticError: Color(0xFFEF5350),
    borderRadiusSmall: 4.0,
    borderRadiusMedium: 8.0,
    spacingUnit: 8.0,
    headingStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF),
    ),
    bodyStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFFE0E0E0),
    ),
  );

  @override
  AppDesignTokens copyWith({
    Color? brandPrimary,
    Color? surfaceElevated,
    Color? semanticError,
    double? borderRadiusSmall,
    double? borderRadiusMedium,
    double? spacingUnit,
    TextStyle? headingStyle,
    TextStyle? bodyStyle,
  }) {
    return AppDesignTokens(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      semanticError: semanticError ?? this.semanticError,
      borderRadiusSmall: borderRadiusSmall ?? this.borderRadiusSmall,
      borderRadiusMedium: borderRadiusMedium ?? this.borderRadiusMedium,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      headingStyle: headingStyle ?? this.headingStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
    );
  }

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      semanticError: Color.lerp(semanticError, other.semanticError, t)!,
      borderRadiusSmall:
          (borderRadiusSmall +
          (other.borderRadiusSmall - borderRadiusSmall) * t),
      borderRadiusMedium:
          (borderRadiusMedium +
          (other.borderRadiusMedium - borderRadiusMedium) * t),
      spacingUnit: (spacingUnit + (other.spacingUnit - spacingUnit) * t),
      headingStyle: TextStyle.lerp(headingStyle, other.headingStyle, t)!,
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppDesignTokens get tokens => Theme.of(this).extension<AppDesignTokens>()!;
}
