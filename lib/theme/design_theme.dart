import 'package:flutter/material.dart';

/// Brand palette — the ONLY place raw hex values are written.
class AppColors {
  AppColors._();

  static const Color hotPink = Color(0xFFF37E9F);
  static const Color pink = Color(0xFFFCBED5);
  static const Color lightPink = Color(0xFFFEECEB);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF000000);

  static const Color darkBackground = Color(0xFF1A1417);
  static const Color darkSurface = Color(0xFF2A2124);
  static const Color darkTextColor = Color(0xFFFEECEB);
}

class DesignTheme {
  DesignTheme._();

  static const TextStyle logoStyle = TextStyle(
    color: AppColors.hotPink,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.5,
  );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.hotPink,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.hotPink,
      secondary: AppColors.pink,
      tertiary: AppColors.lightPink,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: AppColors.textColor,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.textColor,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textColor,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.hotPink,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.hotPink,
      secondary: AppColors.pink,
      tertiary: AppColors.lightPink,
      surface: AppColors.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: AppColors.darkTextColor,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.darkTextColor,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextColor,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}