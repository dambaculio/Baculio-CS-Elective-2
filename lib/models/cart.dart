import 'flower.dart';

/// One line item in the cart: a product plus how many of it.
class CartItem {
  final Flower product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}