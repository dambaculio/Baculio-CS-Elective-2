import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../utils/errors.dart';

class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  static const String _select =
      'id, created_at, user_id, status, total, '
      'order_items(id, product_id, product_name, color, unit_price, quantity)';

  Future<PlacedOrder> placeOrder(List<CartItem> items) async {
    final result = await _client.rpc(
      'place_order',
      params: {
        'p_items': [
          for (final item in items)
            {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'color': item.color,
            },
        ],
      },
    );
    return PlacedOrder.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<List<ShopOrder>> fetchOrdersForUser(String userId) async {
    final rows = await _client
        .from('orders')
        .select(_select)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: true, referencedTable: 'order_items');
    return rows.map(ShopOrder.fromMap).toList();
  }

  Future<List<ShopOrder>> fetchAllOrders() async {
    final rows = await _client
        .from('orders')
        .select(_select)
        .order('created_at', ascending: false)
        .order('id', ascending: true, referencedTable: 'order_items');
    return rows.map(ShopOrder.fromMap).toList();
  }

  Future<void> updateStatus(int orderId, String status) async {
    final row = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw const AppException(
        "You don't have permission to update this order.",
        permissionDenied: true,
      );
    }
  }
}
