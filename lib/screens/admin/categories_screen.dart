import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../providers/category_providers.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';
import '../../utils/responsive.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New category');
    if (name == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryAdminProvider).create(name),
      '"$name" added.',
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ProductCategory category,
  ) async {
    final name = await _promptName(
      context,
      title: 'Rename category',
      initial: category.name,
    );
    if (name == null || name == category.name || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryAdminProvider).rename(category.id, name),
      'Renamed to "$name".',
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProductCategory category,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${category.name}"?',
      message:
          'The category "${category.name}" will be removed. Categories that '
          'still have products cannot be deleted.',
    );
    if (!confirmed || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryAdminProvider).delete(category.id),
      '"${category.name}" deleted.',
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted) showAppSnackBar(context, success);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: AsyncValueView<List<ProductCategory>>(
        value: ref.watch(categoriesProvider),
        onRetry: () => ref.invalidate(categoriesProvider),
        data: (categories) => categories.isEmpty
            ? const MessageView(
                icon: Icons.category_outlined,
                title: 'No categories yet',
                message: 'Add one to start organizing products.',
              )
            : ResponsiveCenter(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_florist_outlined),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Rename',
                              onPressed: () => _rename(context, ref, category),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              color: Colors.red.shade600,
                              onPressed: () => _delete(context, ref, category),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Category name'),
          onFieldSubmitted: (_) => _submit(),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
