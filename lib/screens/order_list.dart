import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/cart.dart';
import '../theme/design_theme.dart';
import '../widgets/product_image.dart';
import 'order_confirmation.dart';

/// Shows everything currently in the cart before checkout.
/// Flow: Product Page -> Add to Cart -> Floating Cart -> Order List
/// (this page) -> Order Confirmation.
class OrderListScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final void Function(String productId, int newQuantity) onUpdateQuantity;
  final void Function(String productId) onRemove;
  final VoidCallback onCheckoutComplete;

  const OrderListScreen({
    super.key,
    required this.cartItems,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onCheckoutComplete,
  });

  double get _total => cartItems.fold(0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Order List')),
      body: cartItems.isEmpty
          ? Center(
              child: Text('Your cart is empty.', style: textTheme.bodyMedium),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: ValueKey(item.product.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) => onRemove(item.product.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: ProductImage(
                            imageUrl: item.product.imageUrl,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.lightPink,
                                  child: const Icon(
                                    Icons.local_florist_outlined,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\u20b1${item.product.price.toStringAsFixed(2)} each',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subtotal: \u20b1${item.subtotal.toStringAsFixed(2)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => onUpdateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => onUpdateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove item',
                                color: Colors.red,
                                onPressed: () => onRemove(item.product.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: textTheme.titleMedium),
                        Text(
                          '\u20b1${_total.toStringAsFixed(2)}',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final totalSnapshot = _total;
                          final itemsSnapshot = List<CartItem>.from(cartItems);
                          onCheckoutComplete();
                          context.push(
                            '/confirmation',
                            extra: OrderSummary(
                              items: itemsSnapshot,
                              total: totalSnapshot,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
