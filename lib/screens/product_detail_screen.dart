import 'package:flutter/material.dart';

/// Product Details Screen
///
/// StatelessWidget because the page is currently static
/// and does not contain any changing state.
class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),

      body: Center(
        child: Text(
          'Product Details',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}