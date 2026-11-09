import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/flower.dart';

/// Shared shopping cart. Every screen that shows the cart (home badge,
/// detail page badge, order list) watches this, so they all rebuild the
/// moment the cart changes.
///
/// (Previously the cart lived in main.dart's setState. go_router doesn't
/// rebuild pages that are already open when an ancestor calls setState,
/// so the order list never showed quantity changes or removals.)
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// Total number of pieces (used for the cart badge).
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  void add(Flower product, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  /// Sets an item's quantity; 0 or less removes it.
  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = newQuantity;
    }
    notifyListeners();
  }

  void remove(String productId) {
    final before = _items.length;
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.length != before) notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
