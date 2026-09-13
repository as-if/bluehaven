import 'package:flutter/material.dart';

class KioskTheme {
  // Sunlight-readable High-Contrast Color Palette
  static const Color primaryBlue = Color(0xFF0077B6);
  static const Color darkBackground = Color(0xFF071322);
  static const Color cardSurface = Color(0xFF0E2238);
  static const Color cardBorder = Color(0xFF1E3A5F);
  static const Color accentCyan = Color(0xFF00F0FF);
  static const Color accentAmber = Color(0xFFFFB703);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentCoral = Color(0xFFEF476F);

  // Minimum touch target sizes for kiosk tablets
  static const double minTouchTargetSize = 64.0;
  static const double buttonHeight = 64.0;
  static const double iconSizeLarge = 36.0;

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryBlue,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentAmber,
        surface: cardSurface,
        error: accentCoral,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white70, height: 1.4),
        bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white60, height: 1.4),
        labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTargetSize, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          elevation: 4,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTargetSize, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: accentCyan, width: 2),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        hintStyle: const TextStyle(fontSize: 20, color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentCyan, width: 2.5),
        ),
      ),
    );
  }
}
