import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/flower.dart';

import '../data/flower_data.dart';
import '../theme/design_theme.dart';
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
  late int _displayedCartItemCount = widget.cartItemCount ?? 0;
  String? _selectedColor;
  late bool _isFavorite = widget.isFavorite;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
    if (oldWidget.cartItemCount != widget.cartItemCount) {
      _displayedCartItemCount = widget.cartItemCount ?? 0;
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
    final supportsColorChoice = switch (product.category.toLowerCase()) {
      'flowers' || 'wrappers' || 'ribbon' || 'ribbons' => true,
      _ => false,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                          child: const Icon(
                            Icons.local_florist_outlined,
                            size: 90,
                          ),
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
                        child: _CartActionButton(
                          itemCount: _displayedCartItemCount,
                          tooltip: 'Cart',
                          onPressed: widget.onCartTap,
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
                          child: Text(
                            product.name,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '\u20b1${product.price.toStringAsFixed(2)}',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Flower Type',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        product.category.isEmpty ? 'Flower' : product.category,
                      ),
                      backgroundColor: AppColors.lightPink,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                    if (supportsColorChoice) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Color *',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colorOptions.map((option) {
                          return _ColorSwatch(
                            label: option.name,
                            color: option.color,
                            selected: _selectedColor == option.name,
                            onTap: () =>
                                setState(() => _selectedColor = option.name),
                          );
                        }).toList(),
                      ),
                    ],
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
                      onPressed:
                          widget.onAddToCart == null ||
                              (supportsColorChoice && _selectedColor == null)
                          ? null
                          : () {
                              setState(() {
                                _displayedCartItemCount += _quantity;
                              });
                              widget.onAddToCart!(product, _quantity);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: AppColors.hotPink,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${product.name} added to cart',
                                            style: const TextStyle(
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      96,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    backgroundColor: AppColors.lightPink,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: AppColors.pink,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                            },
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
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? AppColors.textColor),
      ),
    );
  }
}

class _CartActionButton extends StatelessWidget {
  final int itemCount;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CartActionButton({
    required this.itemCount,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CircleActionButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: tooltip,
          onPressed: onPressed ?? () {},
        ),
        if (itemCount > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$itemCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.hotPink : Colors.black26,
              width: selected ? 1.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;

  const _ColorOption(this.name, this.color);
}

const List<_ColorOption> _colorOptions = [
  _ColorOption('White', Colors.white),
  _ColorOption('Pink', AppColors.pink),
  _ColorOption('Blue', Colors.blue),
  _ColorOption('Red', Colors.red),
  _ColorOption('Yellow', Colors.yellow),
  _ColorOption('Green', Colors.green),
];

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
