import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../theme/design_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder? order;

  @override
  Widget build(BuildContext context) {
    final placed = order;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Placed'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: placed == null
            ? MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No recent order',
                message: 'Your order history has all your past orders.',
                action: FilledButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('View my orders'),
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.lightPink,
                          child: Icon(
                            Icons.check,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Thank you for your order!',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _row(
                                  context,
                                  'Order number',
                                  '#${placed.orderId}',
                                ),
                                const Divider(height: 24),
                                _row(
                                  context,
                                  'Total paid',
                                  formatPeso(placed.total),
                                  highlight: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Saved to your order history.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go('/'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Continue shopping'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              final router = GoRouter.of(context);
                              router.go('/');
                              router.push('/orders');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('View my orders'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: highlight
              ? textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                )
              : textTheme.titleMedium,
        ),
      ],
    );
  }
}
