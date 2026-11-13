import 'flower.dart';

class CartItem {
  final Flower product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}
