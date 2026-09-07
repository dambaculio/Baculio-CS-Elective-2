import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

/// Circular floating cart button with a small item-count badge.
/// Used as the floatingActionButton on both HomeScreen and
/// ProductDetailScreen so the cart is always reachable.
class FloatingCartButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;

  const FloatingCartButton({
    super.key,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor: AppColors.hotPink,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        // Badge only shows when the cart isn't empty.
        if (itemCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$itemCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}