import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_providers.dart';
import '../../theme/design_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/color_swatch.dart';
import '../../widgets/product_actions.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stock_badge.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;

  Future<void> _delete(Product product) async {
    final deleted = await confirmAndDeleteProduct(context, ref, product);
    if (deleted && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final productValue = ref.watch(productByIdProvider(widget.productId));
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView<Product?>(
          value: productValue,
          onRetry: () => ref.invalidate(productByIdProvider(widget.productId)),
          data: (product) => product == null
              ? MessageView(
                  icon: Icons.search_off,
                  title: 'Product not found',
                  message: 'It may have been removed from the shop.',
                  action: FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to shop'),
                  ),
                )
              : _buildProduct(product),
        ),
      ),
    );
  }

  Widget _buildProduct(Product product) {
    final isAdmin = ref.watch(isAdminProvider);
    final isFavorite = ref.watch(favoritesProvider).contains(product.id);
    final inCart = ref
        .watch(cartProvider)
        .where((item) => item.product.id == product.id)
        .fold(0, (sum, item) => sum + item.quantity);
    final available = product.stock - inCart;
    final quantity = available <= 0 ? 0 : _quantity.clamp(1, available);
    final needsColor =
        product.hasColors && !product.colors.contains(_selectedColor);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget imagePanel(double imageHeight, {required bool wide}) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, wide ? 16 : 0),
      child: SizedBox(
        height: imageHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(
                imageUrl: product.imageUrl,
                greyedOut: !product.inStock,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _CircleButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              if (!isAdmin) ...[
                Positioned(
                  top: 12,
                  right: 60,
                  child: _CircleButton(
                    icon: Icons.shopping_cart_outlined,
                    tooltip: 'Cart',
                    badge: ref.watch(cartCountProvider),
                    onPressed: () => context.push('/cart'),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CircleButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    iconColor: AppColors.hotPink,
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(product.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    Widget detailsPanel() => Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  formatPeso(product.price),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StockBadge(stock: product.stock),
                if (product.categoryName != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(product.categoryName!),
                    backgroundColor: AppColors.lightPink,
                    labelStyle: const TextStyle(color: AppColors.textColor),
                    side: BorderSide(color: colorScheme.secondary),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Description', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              product.description.isEmpty
                  ? 'No description yet.'
                  : product.description,
              style: textTheme.bodyMedium,
            ),
            if (product.hasColors) ...[
              const SizedBox(height: 20),
              Text(
                isAdmin ? 'Available colors' : 'Color *',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final name in product.colors)
                    ColorSwatchDot(
                      colorName: name,
                      selected: !isAdmin && _selectedColor == name,
                      onTap: isAdmin
                          ? null
                          : () => setState(() => _selectedColor = name),
                    ),
                ],
              ),
              if (!isAdmin && _selectedColor != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Selected: $_selectedColor',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ],
            if (!isAdmin && inCart > 0) ...[
              const SizedBox(height: 16),
              Text(
                '$inCart already in your cart.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final actionBar = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: isAdmin
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/admin/products/${product.id}/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(product),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                QuantityStepper(
                  quantity: quantity,
                  onDecrease: quantity > 1
                      ? () => setState(() => _quantity = quantity - 1)
                      : null,
                  onIncrease: quantity < available
                      ? () => setState(() => _quantity = quantity + 1)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: available <= 0 || needsColor
                        ? null
                        : () {
                            addProductToCart(
                              context,
                              ref,
                              product,
                              quantity: quantity,
                              color: _selectedColor,
                            );
                            setState(() => _quantity = 1);
                          },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      !product.inStock
                          ? 'Out of stock'
                          : available <= 0
                          ? 'All in cart'
                          : needsColor
                          ? 'Choose a color'
                          : 'Add to Cart',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: imagePanel(double.infinity, wide: true)),
                  Expanded(
                    child: Column(children: [detailsPanel(), actionBar]),
                  ),
                ],
              ),
            ),
          );
        }
        final imageHeight = math.min(320.0, constraints.maxHeight * 0.4);
        return Column(
          children: [
            imagePanel(imageHeight, wide: false),
            detailsPanel(),
            actionBar,
          ],
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, color: iconColor ?? AppColors.textColor),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
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
