import 'package:flutter/material.dart';

/// Kelas utama untuk semua tema yang digunakan dalam aplikasi
class AppTheme {
  // Warna-warna utama
  static const Color primaryColor = Color(0xFF076A3B);      // Hijau tua
  static const Color secondaryColor = Color(0xFF077A4B);    // Sedikit lebih terang
  static const Color accentColor = Color(0xFF0A8C5F);       // Aksen hijau

  /// Tema default aplikasi
  static final ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[300],
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black87),
      displayMedium: TextStyle(color: Colors.black87),
      displaySmall: TextStyle(color: Colors.black87),
      headlineMedium: TextStyle(color: Colors.black87),
      headlineSmall: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
    ),
  );

  /// Variasi tema: Putih sebagai warna utama
  static final ThemeData whitePrimary = ThemeData(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.white,
      secondary: Colors.grey[300]!,
    ),
  );

  /// Variasi tema: Hitam sebagai warna utama (mode gelap)
  static final ThemeData blackPrimary = ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.black,
      secondary: Colors.grey[700]!,
    ),
  );

  /// Variasi tema: Baraja branding (Hijau khas)
  static final ThemeData barajaPrimary = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: Colors.greenAccent,
    ),
  );
}
