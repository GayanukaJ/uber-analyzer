import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF7B7BFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888899);
  static const Color divider = Color(0xFF333355);
  static const Color green = Color(0xFF00C853);
  static const Color yellow = Color(0xFFFFD600);
  static const Color red = Color(0xFFFF5252);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        onSurface: textPrimary,
      ),
      cardTheme: CardTheme(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
    );
  }
}
