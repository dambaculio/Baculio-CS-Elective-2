import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/providers/cart_provider.dart';
import 'package:flutter_application_1/utils/formatters.dart';

Product _product({int id = 1, int stock = 3, double price = 100}) => Product(
  id: id,
  name: 'Rose $id',
  price: price,
  stock: stock,
  categoryId: 1,
);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWithValue('customer-1')],
    );
  });

  tearDown(() => container.dispose());

  CartNotifier cart() => container.read(cartProvider.notifier);

  test('adds products and keeps a running total and count', () {
    cart().add(_product(id: 1, price: 100), 2);
    cart().add(_product(id: 2, price: 50), 1);

    expect(container.read(cartCountProvider), 3);
    expect(container.read(cartTotalProvider), 250);
  });

  test('refuses out-of-stock products', () {
    final result = cart().add(_product(stock: 0), 1);

    expect(result.success, isFalse);
    expect(container.read(cartProvider), isEmpty);
  });

  test('never goes above available stock', () {
    final product = _product(stock: 3);
    final result = cart().add(product, 5);

    expect(result.added, 3);
    expect(container.read(cartProvider).single.quantity, 3);

    cart().updateQuantity(product.id, 10);
    expect(container.read(cartProvider).single.quantity, 3);

    expect(cart().add(product, 1).success, isFalse);
  });

  test('quantity zero removes the item, clear empties the cart', () {
    cart().add(_product(id: 1), 1);
    cart().add(_product(id: 2), 1);

    cart().updateQuantity(1, 0);
    expect(container.read(cartProvider).map((i) => i.product.id), [2]);

    cart().clear();
    expect(container.read(cartProvider), isEmpty);
  });

  test('formats pesos with thousands separators', () {
    expect(formatPeso(1099), '₱1,099.00');
    expect(formatPeso(25.5), '₱25.50');
  });
}
