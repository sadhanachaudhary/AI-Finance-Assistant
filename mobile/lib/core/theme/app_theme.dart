import 'package:flutter/material.dart';

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
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
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

