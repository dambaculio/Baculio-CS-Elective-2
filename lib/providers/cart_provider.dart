import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_providers.dart';

class CartAddResult {
  const CartAddResult({required this.added, this.message});

  final int added;
  final String? message;

  bool get success => added > 0;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    ref.watch(currentUserIdProvider);
    return const [];
  }

  CartAddResult add(Product product, [int quantity = 1]) {
    if (!product.inStock) {
      return CartAddResult(
        added: 0,
        message: '${product.name} is out of stock.',
      );
    }
    final index = state.indexWhere((item) => item.product.id == product.id);
    final current = index >= 0 ? state[index].quantity : 0;
    final room = product.stock - current;
    if (room <= 0) {
      return CartAddResult(
        added: 0,
        message: 'All ${product.stock} available are already in your cart.',
      );
    }
    final added = math.min(quantity, room);
    final updated = CartItem(product: product, quantity: current + added);
    state = index >= 0 ? ([...state]..[index] = updated) : [...state, updated];
    return CartAddResult(
      added: added,
      message: added < quantity
          ? 'Only ${product.stock} in stock, so $added were added.'
          : null,
    );
  }

  void updateQuantity(int productId, int quantity) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final item = state[index];
    final capped = math.min(quantity, item.product.stock);
    if (capped == item.quantity) return;
    state = [...state]..[index] = item.copyWith(quantity: capped);
  }

  void remove(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity),
);

final cartTotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, item) => sum + item.subtotal),
);
