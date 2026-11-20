import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'auth_providers.dart';
import 'product_providers.dart';
import 'service_providers.dart';

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) {
  if (ref.watch(currentUserIdProvider) == null) {
    return const <ProductCategory>[];
  }
  return ref.watch(categoryServiceProvider).fetchAll();
}, retry: (_, _) => null);

class CategoryAdmin {
  CategoryAdmin(this._ref);

  final Ref _ref;

  Future<void> create(String name) async {
    await _ref.read(categoryServiceProvider).create(name);
    _refresh();
  }

  Future<void> rename(int id, String name) async {
    await _ref.read(categoryServiceProvider).rename(id, name);
    _refresh();
  }

  Future<void> delete(int id) async {
    await _ref.read(categoryServiceProvider).delete(id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(productPageProvider);
    _ref.invalidate(productByIdProvider);
  }
}

final categoryAdminProvider = Provider<CategoryAdmin>(
  (ref) => CategoryAdmin(ref),
);
