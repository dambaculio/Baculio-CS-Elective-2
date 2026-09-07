import 'package:flutter/material.dart';

import '../models/flower.dart';
import '../theme/design_theme.dart';
import 'product_image.dart';

/// StatefulWidget: this card holds one small piece of state — whether
/// the user has favorited it.
class FlowerCard extends StatefulWidget {
  final Flower flower;
  final VoidCallback onTap;

  const FlowerCard({
    super.key,
    required this.flower,
    required this.onTap,
  });

  @override
  State<FlowerCard> createState() => _FlowerCardState();
}

class _FlowerCardState extends State<FlowerCard> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.lightPink,
                    child: ProductImage(
                      imageUrl: widget.flower.imageUrl,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.local_florist_outlined, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.flower.name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20b1${widget.flower.price.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
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