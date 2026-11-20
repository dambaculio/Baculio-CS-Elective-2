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

  int quantityOf(int productId) => state
      .where((item) => item.product.id == productId)
      .fold(0, (sum, item) => sum + item.quantity);

  int maxQuantityFor(CartItem item) =>
      item.product.stock - (quantityOf(item.product.id) - item.quantity);

  CartAddResult add(Product product, int quantity, {String? color}) {
    if (!product.inStock) {
      return CartAddResult(
        added: 0,
        message: '${product.name} is out of stock.',
      );
    }
    final String? chosenColor;
    if (product.hasColors) {
      if (color == null || !product.colors.contains(color)) {
        return CartAddResult(
          added: 0,
          message: 'Choose a color for ${product.name} first.',
        );
      }
      chosenColor = color;
    } else {
      chosenColor = null;
    }

    final room = product.stock - quantityOf(product.id);
    if (room <= 0) {
      return CartAddResult(
        added: 0,
        message: 'All ${product.stock} available are already in your cart.',
      );
    }

    final added = math.min(quantity, room);
    final key = CartItem.keyFor(product.id, chosenColor);
    final index = state.indexWhere((item) => item.key == key);
    final current = index >= 0 ? state[index].quantity : 0;
    final updated = CartItem(
      product: product,
      quantity: current + added,
      color: chosenColor,
    );
    state = index >= 0 ? ([...state]..[index] = updated) : [...state, updated];
    return CartAddResult(
      added: added,
      message: added < quantity
          ? 'Only ${product.stock} in stock, so $added were added.'
          : null,
    );
  }

  void updateQuantity(String key, int quantity) {
    final index = state.indexWhere((item) => item.key == key);
    if (index < 0) return;
    if (quantity <= 0) {
      remove(key);
      return;
    }
    final item = state[index];
    final capped = math.min(quantity, maxQuantityFor(item));
    if (capped <= 0 || capped == item.quantity) return;
    state = [...state]..[index] = item.copyWith(quantity: capped);
  }

  void remove(String key) {
    state = state.where((item) => item.key != key).toList();
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
