import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/flower.dart';

import '../data/flower_data.dart';
import '../theme/design_theme.dart';
import '../widgets/floating_cart_button.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final int? cartItemCount;
  final void Function(Flower, int)? onAddToCart;
  final VoidCallback? onCartTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.cartItemCount,
    this.onAddToCart,
    this.onCartTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late bool _isFavorite = widget.isFavorite;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Flower? product = flowerList.cast<Flower?>().firstWhere(
      (f) =>
          f != null && (f.id == widget.productId || f.slug == widget.productId),
      orElse: () => null,
    );

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton:
          widget.onCartTap == null || widget.cartItemCount == null
          ? null
          : FloatingCartButton(
              itemCount: widget.cartItemCount!,
              onTap: widget.onCartTap!,
            ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 330,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        imageUrl: product.imageUrl,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.lightPink,
                          child: const Icon(Icons.local_florist_outlined, size: 90),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _CircleActionButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 64,
                        child: _CircleActionButton(
                          icon: Icons.share_outlined,
                          tooltip: 'Share',
                          onPressed: () {},
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _CircleActionButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          tooltip: _isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          iconColor: _isFavorite
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          onPressed: _toggleFavorite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageDot(active: true, color: colorScheme.primary),
                _PageDot(color: colorScheme.secondary),
                _PageDot(color: colorScheme.secondary),
                _PageDot(color: colorScheme.secondary),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(product.name, style: textTheme.headlineMedium),
                        ),
                        Text(
                          '\u20b1${product.price.toStringAsFixed(2)}',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.star, color: colorScheme.primary, size: 22),
                        Icon(Icons.star, color: colorScheme.primary, size: 22),
                        Icon(Icons.star, color: colorScheme.primary, size: 22),
                        Icon(Icons.star, color: colorScheme.primary, size: 22),
                        Icon(Icons.star, color: colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text('(128)', style: textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Description', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(product.description, style: textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    Text('Flower Type', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(product.category.isEmpty ? 'Flower' : product.category),
                      backgroundColor: AppColors.lightPink,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 16),
                    Text('Color', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ColorSwatch(color: colorScheme.primary, selected: true),
                        const _ColorSwatch(color: AppColors.pink),
                        const _ColorSwatch(color: AppColors.lightPink),
                        const _ColorSwatch(color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  _QuantityStepper(
                    quantity: _quantity,
                    onDecrease: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    onIncrease: () => setState(() => _quantity++),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAddToCart == null
                          ? null
                          : () => widget.onAddToCart!(product, _quantity),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Add to Cart'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _CircleActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? AppColors.textColor),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;
  final Color color;

  const _PageDot({this.active = false, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 9 : 7,
      height: active ? 9 : 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;

  const _ColorSwatch({required this.color, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.hotPink : Colors.transparent,
          width: 2,
        ),
      ),
      child: CircleAvatar(radius: 22, backgroundColor: color),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.lightPink, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease quantity',
          ),
          Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}
