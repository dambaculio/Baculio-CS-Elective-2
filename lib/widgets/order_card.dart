import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/design_theme.dart';
import '../utils/formatters.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.trailing,
    this.showCustomer = false,
  });

  final ShopOrder order;
  final Widget? trailing;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text('Order #${order.id}', style: textTheme.titleMedium),
            ),
            StatusChip(status: order.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCustomer)
                Text(
                  order.customerEmail ??
                      order.customerName ??
                      'Unknown customer',
                  style: textTheme.bodyMedium,
                ),
              Text(
                formatDateTime(order.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · '
                '${formatPeso(order.total)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatPeso(item.subtotal),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatPeso(item.unitPrice)} × ${item.quantity}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              Text('Total', style: textTheme.titleMedium),
              const Spacer(),
              Text(
                formatPeso(order.total),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          if (trailing != null) ...[const SizedBox(height: 12), trailing!],
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.done => Colors.green.shade700,
      OrderStatus.shipped => Colors.blue.shade700,
      OrderStatus.delivered => Colors.teal.shade700,
      OrderStatus.cancelled => Colors.red.shade600,
      _ => Colors.orange.shade800,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        OrderStatus.label(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
