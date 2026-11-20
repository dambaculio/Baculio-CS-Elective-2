import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/categories_screen.dart';
import '../screens/admin/product_form_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/shop/home_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import 'auth_providers.dart';

const _authRoutes = {'/login', '/signup'};
const _customerOnlyRoutes = {'/cart', '/orders', '/order-confirmation'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(currentProfileProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onAuthPage = _authRoutes.contains(location);
      if (ref.read(sessionProvider) == null) {
        return onAuthPage ? null : '/login';
      }
      if (onAuthPage) return '/';

      final profile = ref.read(currentProfileProvider);
      if (!profile.hasValue) return null;
      final isAdmin = profile.value?.isAdmin ?? false;
      if (location.startsWith('/admin') && !isAdmin) return '/';
      if (isAdmin && _customerOnlyRoutes.contains(location)) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(
          productId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const OrderHistoryScreen()),
      GoRoute(
        path: '/order-confirmation',
        builder: (_, state) => OrderConfirmationScreen(
          order: state.extra is PlacedOrder
              ? state.extra! as PlacedOrder
              : null,
        ),
      ),
      GoRoute(
        path: '/admin/products/new',
        builder: (_, _) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (_, state) => ProductFormScreen(
          productId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (_, _) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (_, _) => const CategoriesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to shop'),
        ),
      ),
    ),
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});
