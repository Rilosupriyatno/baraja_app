import 'package:flutter/material.dart';

class AppTheme {
  // Warna utama aplikasi sesuai kode yang diminta (0xFF076A3B)
  static const Color primaryColor = Color(0xFF076A3B);
  static const Color secondaryColor = Color(0xFF077A4B); // Sedikit lebih terang
  static const Color accentColor = Color(0xFF0A8C5F);

  // Tema aplikasi
  static final ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    scaffoldBackgroundColor: Colors.grey[300],
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
}