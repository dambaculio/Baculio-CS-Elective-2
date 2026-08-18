import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'FruitListPage.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const FruitListPage(),
      routes: [
        GoRoute(
          path: 'fruit/:name',
          builder: (BuildContext context, GoRouterState state) {
            final fruitName = state.pathParameters['name'] ?? 'Unknown';
            return FruitDetailPage(fruitName: fruitName);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fruit Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          foregroundColor: Colors.black,
        ),
      ),
      routerConfig: _router,
    );
  }
}