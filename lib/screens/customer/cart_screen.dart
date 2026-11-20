import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_providers.dart';
import '../../theme/design_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/state_views.dart';
import '../../utils/responsive.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final placed = await ref.read(checkoutProvider.notifier).placeOrder();
    if (placed != null && context.mounted) {
      context.go('/order-confirmation', extra: placed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<PlacedOrder?>>(checkoutProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        showErrorSnackBar(context, next.error!);
      }
    });

    final items = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final checkingOut = ref.watch(checkoutProvider).isLoading;
    final cart = ref.read(cartProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add some blooms and they will show up here.',
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Browse products'),
              ),
            )
          : ResponsiveCenter(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final product = item.product;
                  return Dismissible(
                    key: ValueKey(product.id),
                    direction: checkingOut
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => cart.remove(product.id),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: ProductImage(imageUrl: product.imageUrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${formatPeso(product.price)} each',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                              Text(
                                item.quantity >= product.stock
                                    ? 'Max available: ${product.stock}'
                                    : '${product.stock} in stock',
                                style: textTheme.bodySmall?.copyWith(
                                  color: item.quantity >= product.stock
                                      ? Colors.orange.shade800
                                      : AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatPeso(item.subtotal),
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Remove item',
                              color: Colors.red.shade600,
                              onPressed: checkingOut
                                  ? null
                                  : () => cart.remove(product.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                            QuantityStepper(
                              compact: true,
                              quantity: item.quantity,
                              onDecrease: checkingOut
                                  ? null
                                  : () => cart.updateQuantity(
                                      product.id,
                                      item.quantity - 1,
                                    ),
                              onIncrease:
                                  checkingOut || item.quantity >= product.stock
                                  ? null
                                  : () => cart.updateQuantity(
                                      product.id,
                                      item.quantity + 1,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$count item${count == 1 ? '' : 's'}',
                            style: textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text('Total  ', style: textTheme.titleMedium),
                          Text(
                            formatPeso(total),
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: checkingOut
                              ? null
                              : () => _checkout(context, ref),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: checkingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
