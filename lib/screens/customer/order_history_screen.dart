import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/order_providers.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_views.dart';
import '../../utils/responsive.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: AsyncValueView<List<ShopOrder>>(
        value: ref.watch(myOrdersProvider),
        onRetry: () => ref.invalidate(myOrdersProvider),
        data: (orders) => orders.isEmpty
            ? MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Orders you place will show up here.',
                action: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Start shopping'),
                ),
              )
            : ResponsiveCenter(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .refresh(myOrdersProvider.future)
                      .catchError((_) => const <ShopOrder>[]),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => OrderCard(order: orders[index]),
                  ),
                ),
              ),
      ),
    );
  }
}
