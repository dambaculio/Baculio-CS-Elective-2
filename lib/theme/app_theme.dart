import 'package:flutter/material.dart';

/// Light and dark themes for the Pokédex.
class AppTheme {
  AppTheme._();

  static const Color pokedexRed = Color(0xFFE3350D);
  static const Color pokedexRedDark = Color(0xFFB0290A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: pokedexRed,
      primary: pokedexRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F4F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: pokedexRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(color: Colors.white),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: pokedexRed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: pokedexRedDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
    );
  }
}