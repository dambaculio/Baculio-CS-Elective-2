import 'package:flutter/material.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../theme/design_theme.dart';
import 'order_confirmation.dart';

/// StatefulWidget: quantity and the selected color swatch are both
/// mutable UI state, managed here with setState().
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedColorIndex = 0;

  final List<Color> _colorOptions = [
    AppColors.hotPink,
    AppColors.pink,
    AppColors.lightPink,
    Colors.white,
  ];

  // Matches against either `id` or `slug`, so this screen works
  // whichever way a screen pushes to it (/product/1 or /product/tulip-touch).
  Flower get _product => flowerList.firstWhere(
        (f) => f.id == widget.productId || f.slug == widget.productId,
      );

  void _incrementQuantity() => setState(() => _quantity++);

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.lightPink,
                      child: const Icon(Icons.local_florist_outlined, size: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(product.name, style: textTheme.headlineMedium),
                  ),
                  Text(
                    '\u20b1${product.price.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Description', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'A beautiful ${product.category.toLowerCase()} arrangement, '
                'perfect for any special moment.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Category', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Chip(
                label: Text(product.category),
                backgroundColor: AppColors.lightPink,
              ),
              const SizedBox(height: 16),
              Text('Color', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_colorOptions.length, (index) {
                  final isSelected = index == _selectedColorIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colorOptions[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _decrementQuantity,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity', style: textTheme.titleMedium),
                      IconButton(
                        onPressed: _incrementQuantity,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showAddToCartDialog(
                        context,
                        product: product,
                        quantity: _quantity,
                        onCheckout: () {
                          showOrderConfirmedDialog(
                            context,
                            product: product,
                            quantity: _quantity,
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}