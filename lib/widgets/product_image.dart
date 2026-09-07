import 'package:flutter/material.dart';

/// Shows a product image from either a network URL or a local asset.
/// If imageUrl starts with 'assets/', it's loaded with Image.asset;
/// otherwise it falls back to Image.network. This lets you swap
/// individual products over to local photos one at a time.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: fit, errorBuilder: errorBuilder);
    }
    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: errorBuilder,
    );
  }
}