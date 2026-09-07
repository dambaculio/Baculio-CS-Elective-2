import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../theme/design_theme.dart';

/// Final "order placed" confirmation, shown after the user reviews
/// their cart in OrderListScreen and taps "Proceed to Checkout".
void showOrderConfirmedDialog(
  BuildContext context, {
  required List<CartItem> items,
  required double total,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.hotPink),
          SizedBox(width: 8),
          Text('Order Confirmed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thank you! Your order has been placed:'),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${item.product.name} x${item.quantity}'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \u20b1${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDone();
          },
          child: const Text('Done'),
        ),
      ],
    ),
  );
}