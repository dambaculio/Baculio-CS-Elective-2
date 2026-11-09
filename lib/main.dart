import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'models/cart.dart';
import 'models/flower.dart';
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
    // ProductProvider sits above the whole app so the home grid and the
    // detail page share the same product state. init() loads page 1.
    ChangeNotifierProvider(
      create: (_) => ProductProvider()..init(),
      child: const MyApp(),
    ),
  );
}

/// Global shortcut to the Supabase client, usable anywhere in the app.
final supabase = Supabase.instance.client;

/// Root widget. StatefulWidget because it owns both the current
/// ThemeMode AND the shared cart — both are mutable state that the
/// whole app depends on, so both are lifted here and passed down.
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

  // ---- Cart state ----
  final List<CartItem> _cartItems = [];
  final Set<String> _favoriteIds = <String>{};

  int get _cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Flower product, int quantity) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (index >= 0) {
        _cartItems[index].quantity += quantity;
      } else {
        _cartItems.add(CartItem(product: product, quantity: quantity));
      }
    });
  }

  void _updateCartQuantity(String productId, int newQuantity) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index < 0) return;
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
    });
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

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
          cartItemCount: _cartItemCount,
          onCartTap: () => context.push('/cart'),
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
            cartItemCount: _cartItemCount,
            onAddToCart: _addToCart,
            onCartTap: () => context.push('/cart'),
            isFavorite: _favoriteIds.contains(id),
            onToggleFavorite: () => _toggleFavorite(id),
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => OrderListScreen(
          cartItems: _cartItems,
          onUpdateQuantity: _updateCartQuantity,
          onRemove: _removeFromCart,
          onCheckoutComplete: _clearCart,
        ),
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
