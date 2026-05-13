import 'package:flutter/material.dart';

class MacroFitTheme {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Perbaikan warna unselected agar lebih kontras
  static const Color unselectedDark = Color(0xFF2D2D2D);
  static const Color unselectedLight = Color(0xFFE0E0E0);

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        surface: Colors.white,
        onSurface:
            Colors.black87, // Memastikan teks di atas surface berwarna hitam
        outline: Colors.grey.shade300,
      ),
      // Tambahkan TextTheme eksplisit
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardTheme: _cardTheme(isDark: false),
      inputDecorationTheme: _inputTheme(primaryBlue, isDark: false),
      elevatedButtonTheme: _buttonTheme(primaryBlue),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        surface: cardDark,
        onSurface: Colors.white, // Teks di atas surface (kartu/bg) jadi putih
        outline: unselectedDark,
      ),
      // Tambahkan TextTheme untuk Dark Mode
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: _cardTheme(isDark: true),
      inputDecorationTheme: _inputTheme(primaryBlue, isDark: true),
      elevatedButtonTheme: _buttonTheme(primaryBlue),
    );
  }

  static CardThemeData _cardTheme({required bool isDark}) {
    return CardThemeData(
      color: isDark ? cardDark : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color color, {required bool isDark}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
    );
  }

  static ElevatedButtonThemeData _buttonTheme(Color color) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            Colors.grey.shade300, // Warna saat button disable
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    );
  }
}
