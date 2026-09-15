import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Semantic typography tokens and font style definitions across the application.
class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.normal,
    color: AppTheme.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppTheme.textTertiary,
    letterSpacing: 0.2,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}

/// Unified UI decoration system (cards, glassmorphism, badges, and icon squircles).
class AppDecorations {
  static BoxDecoration card({
    Color? color,
    Border? border,
    double borderRadius = 20,
    List<BoxShadow>? shadows,
  }) =>
      BoxDecoration(
        color: color ?? AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
      );

  static BoxDecoration glass({
    List<Color>? gradient,
    Color? borderColor,
    double borderRadius = 20,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: gradient ??
              const [
                Color(0xFFFFFFFF),
                Color(0xFFF9FAFE),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor ?? AppTheme.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration iconBadge(Color color, {double radius = 14}) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      );

  static BoxDecoration pillBadge(Color color, {double radius = 10}) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      );

  static BoxDecoration purpleGradientBadge({double radius = 20}) => BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

class AppTheme {
  // Canvas & Surfaces (Clean Light Palette)
  static const Color bgCanvas = Color(0xFFF8F9FE); // Modern soft indigo canvas
  static const Color bgSlate = Color(0xFFF8F9FE); // Backward compatible
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceSlate = Color(0xFFFFFFFF); // Backward compatible
  static const Color surfaceElevated = Color(0xFFF3F5FA); // Sub-element background
  static const Color borderLight = Color(0xFFEEF0F8); // Clean light border
  static const Color borderSlate = Color(0xFFEEF0F8); // Backward compatible

  // Signature Iris Purple Brand & Accents
  static const Color primaryPurple = Color(0xFF6C5CE7); // Royal Iris Purple
  static const Color primaryPurpleDark = Color(0xFF5849D6);
  static const Color primaryPurpleLight = Color(0xFF8E7CFF);
  static const Color accentSparkle = Color(0xFF7C4DFF); // Glowing Sparkle Purple
  static const Color softPurpleBadge = Color(0xFFF0EDFF);

  // Trust & Action Accents
  static const Color trustBlue = Color(0xFF6C5CE7);
  static const Color trustTeal = Color(0xFF0D9488);

  // Transactional & Behavioral Accents
  static const Color inflowGreen = Color(0xFF10B981); // Emerald Mint
  static const Color softGreenBadge = Color(0xFFECFDF5);
  static const Color outflowCoral = Color(0xFFEF4444); // Crimson / Coral
  static const Color softRedBadge = Color(0xFFFEF2F2);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Typography tokens (High Contrast Crisp Dark Text)
  static const Color textPrimary = Color(0xFF1A1D1E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBalanceGradient = LinearGradient(
    colors: [Color(0xFF1A1D2E), Color(0xFF0F111E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tonal visualization family
  static const List<Color> chartTonalColors = [
    Color(0xFF6C5CE7), // Primary Iris Purple
    Color(0xFF8E7CFF), // Soft Violet
    Color(0xFF10B981), // Emerald
    Color(0xFF38BDF8), // Sky Cyan
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFFEF4444), // Warm Coral
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
  ];

  static TextStyle tabularNumbers({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
      letterSpacing: letterSpacing,
      fontFeatures: kIsWeb ? const [] : const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgCanvas,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: accentSparkle,
        surface: surfaceCard,
        error: outflowCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.h3,
        labelMedium: AppTypography.bodySmall,
        labelSmall: AppTypography.badge,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPurple, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outflowCoral, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryPurple.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryPurple);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primaryPurple,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
    );
  }

  // Backward-compatible dark theme alias
  static ThemeData get darkTheme => lightTheme;
}
