import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final double total;
  final VoidCallback onBackToHome;

  const OrderConfirmationScreen({
    super.key,
    required this.total,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.lightPink,
                child: Icon(Icons.check, size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Thank You for Ordering!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been successfully placed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Text(
                'Order total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '\u20b1${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBackToHome,
                  child: const Text('Back to Homepage'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
