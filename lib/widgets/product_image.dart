import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.greyedOut = false,
  });

  final String? imageUrl;
  final BoxFit fit;
  final bool greyedOut;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (!greyedOut) return image;
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(colorFilter: _greyscale, child: image),
    );
  }

  Widget _buildImage() {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const _Placeholder();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => const _Placeholder(),
      );
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, _, _) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.lightPink,
    alignment: Alignment.center,
    child: const Icon(
      Icons.local_florist_outlined,
      size: 40,
      color: AppColors.hotPink,
    ),
  );
}
