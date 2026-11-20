import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import 'auth_providers.dart';
import 'cart_provider.dart';
import 'product_providers.dart';
import 'service_providers.dart';

final myOrdersProvider = FutureProvider<List<ShopOrder>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(orderServiceProvider).fetchOrdersForUser(userId);
}, retry: (_, _) => null);

final adminOrdersProvider = FutureProvider<List<ShopOrder>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return const [];
  final orderService = ref.watch(orderServiceProvider);
  final profileService = ref.watch(profileServiceProvider);
  final orders = await orderService.fetchAllOrders();
  final profiles = await profileService.fetchProfiles(
    orders.map((o) => o.userId).whereType<String>(),
  );
  return [
    for (final order in orders)
      order.withCustomer(
        name: profiles[order.userId]?.displayName,
        email: profiles[order.userId]?.email,
      ),
  ];
}, retry: (_, _) => null);

class OrderAdmin {
  OrderAdmin(this._ref);

  final Ref _ref;

  Future<void> updateStatus(int orderId, String status) async {
    await _ref.read(orderServiceProvider).updateStatus(orderId, status);
    _ref.invalidate(adminOrdersProvider);
  }
}

final orderAdminProvider = Provider<OrderAdmin>((ref) => OrderAdmin(ref));

class CheckoutNotifier extends Notifier<AsyncValue<PlacedOrder?>> {
  @override
  AsyncValue<PlacedOrder?> build() {
    ref.watch(currentUserIdProvider);
    return const AsyncData(null);
  }

  Future<PlacedOrder?> placeOrder() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty || state.isLoading) return null;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(orderServiceProvider)
          .placeOrder(items)
          .timeout(const Duration(seconds: 20)),
    );
    if (!ref.mounted) return null;
    state = result;
    final placed = result.value;
    if (placed != null) {
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(productPageProvider);
      ref.invalidate(productByIdProvider);
    }
    return placed;
  }

  void reset() => state = const AsyncData(null);
}

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, AsyncValue<PlacedOrder?>>(
      CheckoutNotifier.new,
    );
