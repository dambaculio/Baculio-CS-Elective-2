import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_providers.dart';
import 'dialogs.dart';

void addProductToCart(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  int quantity = 1,
}) {
  final result = ref.read(cartProvider.notifier).add(product, quantity);
  if (!result.success) {
    showAppSnackBar(context, result.message!, isError: true);
    return;
  }
  showAppSnackBar(
    context,
    result.message ??
        '${product.name}${quantity > 1 ? ' ×$quantity' : ''} added to cart',
  );
}

Future<bool> confirmAndDeleteProduct(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete "${product.name}"?',
    message:
        '"${product.name}" will be permanently removed from the shop. '
        'Past orders keep their own copy of its name and price.',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(productAdminProvider).delete(product);
    if (context.mounted) showAppSnackBar(context, '"${product.name}" deleted.');
    return true;
  } catch (error) {
    if (context.mounted) showErrorSnackBar(context, error);
    return false;
  }
}
