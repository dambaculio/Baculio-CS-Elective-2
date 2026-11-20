import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers/order_providers.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_views.dart';
import '../../utils/responsive.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _statusFilter;
  final Set<int> _updating = {};

  Future<void> _updateStatus(ShopOrder order, String status) async {
    if (status == order.status) return;
    setState(() => _updating.add(order.id));
    try {
      await ref.read(orderAdminProvider).updateStatus(order.id, status);
      if (mounted) {
        showAppSnackBar(
          context,
          'Order #${order.id} marked as ${OrderStatus.label(status)}.',
        );
      }
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _updating.remove(order.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: AsyncValueView<List<ShopOrder>>(
        value: ref.watch(adminOrdersProvider),
        onRetry: () => ref.invalidate(adminOrdersProvider),
        data: (orders) {
          final shown = _statusFilter == null
              ? orders
              : orders.where((o) => o.status == _statusFilter).toList();
          return ResponsiveCenter(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .refresh(adminOrdersProvider.future)
                  .catchError((_) => const <ShopOrder>[]),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(null, 'All (${orders.length})'),
                        for (final status in OrderStatus.all)
                          _filterChip(
                            status,
                            '${OrderStatus.label(status)} '
                            '(${orders.where((o) => o.status == status).length})',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: MessageView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders here',
                        message: 'Orders customers place will appear here.',
                      ),
                    )
                  else
                    for (final order in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderCard(
                          order: order,
                          showCustomer: true,
                          trailing: Row(
                            children: [
                              const Text('Status'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: order.status,
                                      isExpanded: true,
                                      items: [
                                        for (final status in OrderStatus.all)
                                          DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              OrderStatus.label(status),
                                            ),
                                          ),
                                      ],
                                      onChanged: _updating.contains(order.id)
                                          ? null
                                          : (v) {
                                              if (v != null) {
                                                _updateStatus(order, v);
                                              }
                                            },
                                    ),
                                  ),
                                ),
                              ),
                              if (_updating.contains(order.id)) ...[
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String? status, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _statusFilter == status,
      onSelected: (_) => setState(() => _statusFilter = status),
    ),
  );
}
