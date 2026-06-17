import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Gulf Brand Palette ───────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDark = Color(0xFF9A7A1B);
  static const Color navy = Color(0xFF0A2540);
  static const Color navyLight = Color(0xFF0d3351);
  static const Color navyDeep = Color(0xFF071a2d);
  static const Color darkSurface = Color(0xFF0d1b2a);
  static const Color cardBg = Color(0xFF112240);
  static const Color cardBgLight = Color(0xFF1a2f4a);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCDD8E7);
  static const Color textMuted = Color(0xFF8899AA);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color dividerColor = Color(0xFF1E3A5F);
}

// ─── Design Tokens ────────────────────────────────────────────────────────────
@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    required this.brandPrimary,
    required this.brandGold,
    required this.brandGoldLight,
    required this.surfaceElevated,
    required this.surfaceCard,
    required this.surfaceDeep,
    required this.semanticError,
    required this.semanticSuccess,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.borderRadiusSmall,
    required this.borderRadiusMedium,
    required this.borderRadiusLarge,
    required this.borderRadiusXL,
    required this.spacingUnit,
    required this.headingStyle,
    required this.headingLargeStyle,
    required this.subheadingStyle,
    required this.bodyStyle,
    required this.bodySmallStyle,
    required this.captionStyle,
    required this.priceStyle,
    required this.cardShadow,
    required this.elevatedShadow,
    // kept for backward compat
    required this.brandPrimaryLegacy,
    required this.surfaceElevatedLegacy,
    required this.semanticErrorLegacy,
  });

  final Color brandPrimary;
  final Color brandGold;
  final Color brandGoldLight;
  final Color surfaceElevated;
  final Color surfaceCard;
  final Color surfaceDeep;
  final Color semanticError;
  final Color semanticSuccess;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final double borderRadiusSmall;
  final double borderRadiusMedium;
  final double borderRadiusLarge;
  final double borderRadiusXL;
  final double spacingUnit;
  final TextStyle headingStyle;
  final TextStyle headingLargeStyle;
  final TextStyle subheadingStyle;
  final TextStyle bodyStyle;
  final TextStyle bodySmallStyle;
  final TextStyle captionStyle;
  final TextStyle priceStyle;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;

  // backward compat aliases
  final Color brandPrimaryLegacy;
  final Color surfaceElevatedLegacy;
  final Color semanticErrorLegacy;

  static AppDesignTokens dark() => AppDesignTokens(
    brandPrimary: AppColors.navy,
    brandGold: AppColors.gold,
    brandGoldLight: AppColors.goldLight,
    surfaceElevated: AppColors.cardBg,
    surfaceCard: AppColors.cardBgLight,
    surfaceDeep: AppColors.navyDeep,
    semanticError: AppColors.error,
    semanticSuccess: AppColors.success,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    divider: AppColors.dividerColor,
    borderRadiusSmall: 6.0,
    borderRadiusMedium: 12.0,
    borderRadiusLarge: 20.0,
    borderRadiusXL: 28.0,
    spacingUnit: 8.0,
    headingStyle: GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    headingLargeStyle: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1.0,
    ),
    subheadingStyle: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.6,
    ),
    bodySmallStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.5,
    ),
    captionStyle: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
    priceStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.gold,
      letterSpacing: -0.3,
    ),
    cardShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ],
    brandPrimaryLegacy: AppColors.navy,
    surfaceElevatedLegacy: AppColors.cardBg,
    semanticErrorLegacy: AppColors.error,
  );

  static AppDesignTokens light() => AppDesignTokens(
    brandPrimary: AppColors.navy,
    brandGold: AppColors.gold,
    brandGoldLight: AppColors.goldLight,
    surfaceElevated: const Color(0xFFFFFFFF),
    surfaceCard: const Color(0xFFF8F9FA),
    surfaceDeep: const Color(0xFFE9ECEF),
    semanticError: AppColors.error,
    semanticSuccess: AppColors.success,
    textPrimary: AppColors.navy,
    textSecondary: const Color(0xFF334155),
    textMuted: const Color(0xFF64748B),
    divider: const Color(0xFFE2E8F0),
    borderRadiusSmall: 6.0,
    borderRadiusMedium: 12.0,
    borderRadiusLarge: 20.0,
    borderRadiusXL: 28.0,
    spacingUnit: 8.0,
    headingStyle: GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
      letterSpacing: -0.5,
    ),
    headingLargeStyle: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: AppColors.navy,
      letterSpacing: -1.0,
    ),
    subheadingStyle: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.navy,
    ),
    bodyStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF334155),
      height: 1.6,
    ),
    bodySmallStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF64748B),
      height: 1.5,
    ),
    captionStyle: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF64748B),
      letterSpacing: 0.5,
    ),
    priceStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.gold,
      letterSpacing: -0.3,
    ),
    cardShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.1),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ],
    brandPrimaryLegacy: AppColors.navy,
    surfaceElevatedLegacy: Colors.white,
    semanticErrorLegacy: AppColors.error,
  );

  @override
  AppDesignTokens copyWith({
    Color? brandPrimary,
    Color? brandGold,
    Color? brandGoldLight,
    Color? surfaceElevated,
    Color? surfaceCard,
    Color? surfaceDeep,
    Color? semanticError,
    Color? semanticSuccess,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    double? borderRadiusSmall,
    double? borderRadiusMedium,
    double? borderRadiusLarge,
    double? borderRadiusXL,
    double? spacingUnit,
    TextStyle? headingStyle,
    TextStyle? headingLargeStyle,
    TextStyle? subheadingStyle,
    TextStyle? bodyStyle,
    TextStyle? bodySmallStyle,
    TextStyle? captionStyle,
    TextStyle? priceStyle,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedShadow,
    Color? brandPrimaryLegacy,
    Color? surfaceElevatedLegacy,
    Color? semanticErrorLegacy,
  }) =>
      AppDesignTokens(
        brandPrimary: brandPrimary ?? this.brandPrimary,
        brandGold: brandGold ?? this.brandGold,
        brandGoldLight: brandGoldLight ?? this.brandGoldLight,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        surfaceCard: surfaceCard ?? this.surfaceCard,
        surfaceDeep: surfaceDeep ?? this.surfaceDeep,
        semanticError: semanticError ?? this.semanticError,
        semanticSuccess: semanticSuccess ?? this.semanticSuccess,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        divider: divider ?? this.divider,
        borderRadiusSmall: borderRadiusSmall ?? this.borderRadiusSmall,
        borderRadiusMedium: borderRadiusMedium ?? this.borderRadiusMedium,
        borderRadiusLarge: borderRadiusLarge ?? this.borderRadiusLarge,
        borderRadiusXL: borderRadiusXL ?? this.borderRadiusXL,
        spacingUnit: spacingUnit ?? this.spacingUnit,
        headingStyle: headingStyle ?? this.headingStyle,
        headingLargeStyle: headingLargeStyle ?? this.headingLargeStyle,
        subheadingStyle: subheadingStyle ?? this.subheadingStyle,
        bodyStyle: bodyStyle ?? this.bodyStyle,
        bodySmallStyle: bodySmallStyle ?? this.bodySmallStyle,
        captionStyle: captionStyle ?? this.captionStyle,
        priceStyle: priceStyle ?? this.priceStyle,
        cardShadow: cardShadow ?? this.cardShadow,
        elevatedShadow: elevatedShadow ?? this.elevatedShadow,
        brandPrimaryLegacy: brandPrimaryLegacy ?? this.brandPrimaryLegacy,
        surfaceElevatedLegacy:
            surfaceElevatedLegacy ?? this.surfaceElevatedLegacy,
        semanticErrorLegacy: semanticErrorLegacy ?? this.semanticErrorLegacy,
      );

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return copyWith(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t),
      brandGold: Color.lerp(brandGold, other.brandGold, t),
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t),
      semanticError: Color.lerp(semanticError, other.semanticError, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t),
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t),
      borderRadiusSmall:
          borderRadiusSmall + (other.borderRadiusSmall - borderRadiusSmall) * t,
      borderRadiusMedium:
          borderRadiusMedium +
          (other.borderRadiusMedium - borderRadiusMedium) * t,
      spacingUnit: spacingUnit + (other.spacingUnit - spacingUnit) * t,
      headingStyle: TextStyle.lerp(headingStyle, other.headingStyle, t),
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppDesignTokens get tokens => Theme.of(this).extension<AppDesignTokens>()!;
}
