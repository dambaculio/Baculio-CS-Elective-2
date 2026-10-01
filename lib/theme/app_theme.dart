import 'package:flutter/material.dart';

/// Light and dark themes for the Pokédex.
/// All brand colors live here so every widget reads them from one place.
class AppTheme {
  AppTheme._();

  static const Color pokedexRed = Color(0xFFC74634);
  static const Color pokedexRedDark = Color(0xFFA93628);

  // Logo / toggle colors
  static const Color pokeYellow = Color(0xFFFFCB05);
  static const Color pokeBlue = Color(0xFF3B4CCA);
  static const Color pokeBlack = Color(0xFF2B2B2B);
  static const Color pokeWhite = Color(0xFFFFFFFF);

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
        backgroundColor: pokedexRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
    );
  }
}
