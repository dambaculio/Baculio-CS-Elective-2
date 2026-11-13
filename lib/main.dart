import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_confirmation.dart';
import 'screens/order_list.dart';
import 'screens/product_detail_screen.dart';
import 'theme/design_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final Set<String> _favoriteIds = <String>{};
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (!_favoriteIds.add(productId)) {
        _favoriteIds.remove(productId);
      }
    });
    context.read<ProductProvider>().setFavoriteIds(_favoriteIds);
  }

  GoRouter _buildRouter(AuthProvider auth) => GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final onLogin = state.matchedLocation == '/login';
      if (!auth.isSignedIn) return onLogin ? null : '/login';
      if (onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
          favoriteIds: _favoriteIds,
          onToggleFavorite: _toggleFavorite,
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(
            productId: id,
            isFavorite: _favoriteIds.contains(id),
            onToggleFavorite: () => _toggleFavorite(id),
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) {
          final summary = state.extra is OrderSummary
              ? state.extra! as OrderSummary
              : const OrderSummary(items: [], total: 0);
          return OrderConfirmationScreen(
            total: summary.total,
            cartItems: summary.items,
            onBackToHome: () => context.go('/'),
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
      theme: DesignTheme.lightTheme,
      darkTheme: DesignTheme.darkTheme,
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
