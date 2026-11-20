class OrderStatus {
  OrderStatus._();

  static const String pending = 'pending';
  static const String done = 'done';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static const List<String> all = [
    pending,
    done,
    shipped,
    delivered,
    cancelled,
  ];

  static String label(String status) => switch (status) {
    pending => 'Pending',
    done => 'Done',
    shipped => 'Shipped',
    delivered => 'Delivered',
    cancelled => 'Cancelled',
    _ => status,
  };
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.productId,
  });

  final int id;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    id: (map['id'] as num).toInt(),
    productId: (map['product_id'] as num?)?.toInt(),
    productName: _nameFrom(map['products']),
    unitPrice: ((map['unit_price'] as num?) ?? 0).toDouble(),
    quantity: ((map['quantity'] as num?) ?? 0).toInt(),
  );
}

String _nameFrom(Object? product) => product is Map && product['name'] is String
    ? product['name'] as String
    : 'Product';

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.items,
    this.userId,
    this.customerName,
    this.customerEmail,
  });

  final int id;
  final DateTime createdAt;
  final String? userId;
  final String status;
  final double total;
  final List<OrderItem> items;
  final String? customerName;
  final String? customerEmail;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  ShopOrder withCustomer({String? name, String? email}) => ShopOrder(
    id: id,
    createdAt: createdAt,
    userId: userId,
    status: status,
    total: total,
    items: items,
    customerName: name,
    customerEmail: email,
  );

  factory ShopOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['order_items'] as List?) ?? const [];
    return ShopOrder(
      id: (map['id'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      userId: map['user_id'] as String?,
      status: (map['status'] as String?) ?? OrderStatus.pending,
      total: ((map['total'] as num?) ?? 0).toDouble(),
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(OrderItem.fromMap)
          .toList(),
    );
  }
}

class PlacedOrder {
  const PlacedOrder({required this.orderId, required this.total});

  final int orderId;
  final double total;

  factory PlacedOrder.fromMap(Map<String, dynamic> map) => PlacedOrder(
    orderId: (map['order_id'] as num).toInt(),
    total: ((map['total'] as num?) ?? 0).toDouble(),
  );
}
