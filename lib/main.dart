import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'theme/design_theme.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget.
/// StatefulWidget because it manages the current ThemeMode.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  /// Toggles between light and dark mode.
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
    });
  }

  /// Navigation 2.0 using go_router.
  ///
  /// Routes:
  /// /               -> Home Screen
  /// /product/:id    -> Product Details Screen
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
        ),
      ),

      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return ProductDetailScreen(
            productId: id,
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Shai's Creation",
      debugShowCheckedModeBanner: false,

      // Light theme
      theme: DesignTheme.lightTheme,

      // Dark theme
      darkTheme: DesignTheme.darkTheme,

      // Current theme
      themeMode: _themeMode,

      // Navigation 2.0
      routerConfig: _router,
    );
  }
}