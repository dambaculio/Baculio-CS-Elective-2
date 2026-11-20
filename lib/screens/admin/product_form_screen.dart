import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_providers.dart';
import '../../providers/product_providers.dart';
import '../../theme/design_theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/product_image.dart';
import '../../widgets/state_views.dart';
import '../../utils/responsive.dart';

class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    final categories = ref.watch(categoriesProvider);

    Widget formFor(Product? product) => AsyncValueView<List<ProductCategory>>(
      value: categories,
      onRetry: () => ref.invalidate(categoriesProvider),
      data: (list) => list.isEmpty
          ? MessageView(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Create a category before adding products.',
              action: FilledButton(
                onPressed: () => context.push('/admin/categories'),
                child: const Text('Manage categories'),
              ),
            )
          : _ProductForm(initial: product, categories: list),
    );

    return Scaffold(
      appBar: AppBar(title: Text(id == null ? 'Add Product' : 'Edit Product')),
      body: id == null
          ? formFor(null)
          : AsyncValueView<Product?>(
              value: ref.watch(productByIdProvider(id)),
              onRetry: () => ref.invalidate(productByIdProvider(id)),
              data: (product) => product == null
                  ? const MessageView(
                      icon: Icons.search_off,
                      title: 'Product not found',
                      message: 'It may have been deleted.',
                    )
                  : formFor(product),
            ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.initial, required this.categories});

  final Product? initial;
  final List<ProductCategory> categories;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  static const int _maxStock = 32767;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  int? _categoryId;
  String? _existingImageUrl;
  PickedImage? _newImage;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final product = widget.initial;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(
      text: product == null ? '' : _formatNumber(product.price),
    );
    _stock = TextEditingController(text: product?.stock.toString() ?? '');
    _existingImageUrl = product?.imageUrl;
    final ids = widget.categories.map((c) => c.id).toSet();
    _categoryId = product != null && ids.contains(product.categoryId)
        ? product.categoryId
        : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(
        () => _newImage = PickedImage(
          bytes: bytes,
          fileName: file.name,
          mimeType: file.mimeType,
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          "Couldn't open the image: $error",
          isError: true,
        );
      }
    }
  }

  void _removeImage() => setState(() {
    _newImage = null;
    _existingImageUrl = null;
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final draft = ProductDraft(
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: double.parse(_price.text.trim()),
      stock: int.parse(_stock.text.trim()),
      categoryId: _categoryId!,
      imageUrl: _existingImageUrl,
    );
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(productAdminProvider)
          .save(
            productId: widget.initial?.id,
            draft: draft,
            newImage: _newImage,
          );
      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEditing ? '"${saved.name}" updated.' : '"${saved.name}" added.',
      );
      context.pop();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';
    final price = double.tryParse(text);
    if (price == null) return 'Enter a number, like 499 or 499.50';
    if (price < 0) return 'Price cannot be negative';
    return null;
  }

  String? _validateStock(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Stock is required';
    final stock = int.tryParse(text);
    if (stock == null) return 'Stock must be a whole number';
    if (stock < 0) return 'Stock cannot be negative';
    if (stock > _maxStock) return 'Stock cannot be more than $_maxStock';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _newImage != null || _existingImageUrl != null;

    return ResponsiveCenter(
      maxWidth: formMaxWidth,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: _newImage != null
                      ? Image.memory(_newImage!.bytes, fit: BoxFit.cover)
                      : ProductImage(imageUrl: _existingImageUrl),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasImage ? 'Change image' : 'Choose image'),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: _saving ? null : _removeImage,
                    icon: const Icon(Icons.close),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              enabled: !_saving,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      prefixText: '₱ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Stock *',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.hotPink,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
