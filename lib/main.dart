import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';
import 'screens/order_list.dart';
import 'screens/order_confirmation.dart';
import 'screens/product_detail_screen.dart';
import 'theme/design_theme.dart';

Future<void> main() async {
  // Needed because we await a plugin call before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    // Providers sit above the whole app so every screen shares the same
    // product and cart state. ProductProvider.init() loads page 1.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Global shortcut to the Supabase client, usable anywhere in the app.
final supabase = Supabase.instance.client;

/// Root widget. StatefulWidget because it owns the current ThemeMode and
/// the favorites set. Products and the cart live in providers (see
/// main() above) so every screen rebuilds when they change.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  final Set<String> _favoriteIds = <String>{};

  void _toggleFavorite(String productId) {
    setState(() {
      if (!_favoriteIds.add(productId)) {
        _favoriteIds.remove(productId);
      }
    });
    // The Favorites tab is a Supabase query too, so keep it in sync.
    context.read<ProductProvider>().setFavoriteIds(_favoriteIds);
  }

  /// Navigation 2.0 (go_router) route table:
  ///   /              -> Home (Product Grid)
  ///   /product/:id   -> Product Detail Page
  ///   /cart          -> Order List Page
  late final GoRouter _router = GoRouter(
    routes: [
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
