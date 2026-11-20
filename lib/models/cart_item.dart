import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity, this.color});

  final Product product;
  final int quantity;
  final String? color;

  String get key => keyFor(product.id, color);

  double get subtotal => product.price * quantity;

  static String keyFor(int productId, String? color) =>
      '$productId|${color ?? ''}';

  CartItem copyWith({Product? product, int? quantity}) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    color: color,
  );
}
