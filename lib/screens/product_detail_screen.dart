import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/flower.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/design_theme.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  late bool _isFavorite = widget.isFavorite;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  bool _loading = false;
  bool _busy = false; // true while an update/delete is in flight

  @override
  void initState() {
    super.initState();
    // Opened directly (e.g. deep link) before the list loaded it:
    // fetch this one product from Supabase.
    if (context.read<ProductProvider>().findById(widget.productId) == null) {
      _loading = true;
      _loadProduct(); // initState can't be async, so call a helper
    }
  }

  Future<void> _loadProduct() async {
    try {
      await context.read<ProductProvider>().loadProduct(widget.productId);
    } catch (_) {
      // Not found / offline: the "Product not found." view is shown.
    } finally {
      // The widget may have been closed while we waited.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _editProduct(Flower product) async {
    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditProductDialog(product: product),
    );
    if (changes == null || changes.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<ProductProvider>().updateProduct(product.id, changes);
      _showMessage('Product updated.');
    } catch (e) {
      _showMessage('Update failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteProduct(Flower product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '"${product.name}" will be permanently removed from the shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final cart = context.read<CartProvider>();
      await context.read<ProductProvider>().deleteProduct(product.id);
      cart.remove(product.id); // a deleted product can't stay in the cart
      navigator.pop(); // back to the shop
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showMessage('Delete failed: $e', error: true);
      }
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Flower? product = context.watch<ProductProvider>().findById(
      widget.productId,
    );

    if (product == null && (_loading || _busy)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                          itemCount: context.watch<CartProvider>().itemCount,
                          tooltip: 'Cart',
                          onPressed: () => context.push('/cart'),
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
                    const SizedBox(height: 24),
                    Text(
                      'Manage Product',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _editProduct(product),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _deleteProduct(product),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
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
                          supportsColorChoice && _selectedColor == null
                          ? null
                          : () {
                              context.read<CartProvider>().add(
                                product,
                                _quantity,
                              );
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
                      // Tell the customer why the button is disabled.
                      label: Text(
                        supportsColorChoice && _selectedColor == null
                            ? 'Choose a color'
                            : 'Add to Cart',
                      ),
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


/// Form for editing a product. Returns only the columns that changed
/// (as a map ready for Supabase .update()), or null if cancelled.
class _EditProductDialog extends StatefulWidget {
  final Flower product;

  const _EditProductDialog({required this.product});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  static const List<String> _categories = [
    'Bouquet',
    'Flowers',
    'Wrappers',
    'Ribbons',
  ];

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product.name);
  late final _price = TextEditingController(
    text: widget.product.price.toStringAsFixed(2),
  );
  late final _description = TextEditingController(
    text: widget.product.description,
  );
  late String _category = _categories.contains(widget.product.category)
      ? widget.product.category
      : _categories.first;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final p = widget.product;
    final name = _name.text.trim();
    final price = double.parse(_price.text.trim());
    final description = _description.text.trim();

    final changes = <String, dynamic>{
      if (name != p.name) 'name': name,
      if (price != p.price) 'price': price,
      if (description != p.description) 'description': description,
      if (_category != p.category) 'category': _category,
    };
    Navigator.of(context).pop(changes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\u20b1 ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final value = double.tryParse(v?.trim() ?? '');
                    if (value == null) return 'Enter a valid number';
                    if (value < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in _categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
