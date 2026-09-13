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
    color: Colors.white38,
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
    double borderRadius = 16,
    List<BoxShadow>? shadows,
  }) =>
      BoxDecoration(
        color: color ?? AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppTheme.borderSlate, width: 1),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
          colors: gradient ?? const [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.09),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration iconBadge(Color color, {double radius = 12}) => BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      );

  static BoxDecoration pillBadge(Color color, {double radius = 8}) => BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );
}

class AppTheme {
  // 60% Calm Foundation
  static const Color bgSlate = Color(0xFF121826);
  static const Color surfaceSlate = Color(0xFF1A2232);
  static const Color surfaceElevated = Color(0xFF222C3F);
  static const Color borderSlate = Color(0xFF27354E);

  // 30% Trust & Navigation
  static const Color trustBlue = Color(0xFF2563EB);
  static const Color trustTeal = Color(0xFF0D9488);
  static const Color primaryPurple = Color(0xFF6366F1);

  // 10% Transactional & Behavioral Accents
  static const Color inflowGreen = Color(0xFF10B981); // Mint emerald for earnings / savings
  static const Color outflowCoral = Color(0xFFFB7185); // Warm terracotta coral for spending
  static const Color warningAmber = Color(0xFFF59E0B); // Amber for budget warnings

  // Typography tokens
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Tonal visualization family
  static const List<Color> chartTonalColors = [
    Color(0xFF3B82F6), // Trust Blue
    Color(0xFF0D9488), // Ocean Teal
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Sky Cyan
    Color(0xFF8B5CF6), // Soft Violet
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFFFB7185), // Warm Coral
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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgSlate,
      colorScheme: const ColorScheme.dark(
        primary: trustBlue,
        secondary: trustTeal,
        surface: surfaceSlate,
        error: outflowCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
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
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: trustBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: trustBlue.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSlate,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSlate, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSlate, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: trustBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outflowCoral, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F1420),
        indicatorColor: trustBlue.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: trustBlue);
          }
          return const IconThemeData(color: Colors.white54);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trustBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          );
        }),
      ),
    );
  }
}
