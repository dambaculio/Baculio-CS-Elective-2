import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/design_theme.dart';
import '../utils/formatters.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.actions,
    this.isFavorite,
    this.onToggleFavorite,
  });

  final Product product;
  final VoidCallback onTap;
  final List<Widget> actions;
  final bool? isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soldOut = !product.inStock;
    final mutedText = soldOut
        ? AppColors.mutedText
        : theme.textTheme.titleMedium?.color;

    final image = ProductImage(imageUrl: product.imageUrl, greyedOut: soldOut);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: soldOut
          ? Color.alphaBlend(
              AppColors.mutedText.withValues(alpha: 0.12),
              theme.cardTheme.color ?? theme.colorScheme.surface,
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (soldOut)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  if (isFavorite != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          tooltip: isFavorite!
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite!
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: AppColors.hotPink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    soldOut ? 'Out of stock' : '${product.stock} in stock',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatPeso(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: soldOut
                              ? AppColors.mutedText
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
