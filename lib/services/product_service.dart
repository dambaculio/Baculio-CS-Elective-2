import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../utils/errors.dart';

enum SortOption { defaultOrder, priceLowHigh, priceHighLow }

class ProductService {
  ProductService(this._client);

  final SupabaseClient _client;

  static const String _table = 'products';
  static const String _select =
      'id, name, description, price, stock, image_url, category_id, colors, '
      'categories(name)';

  Future<ProductPage> fetchPage({
    required int page,
    required int pageSize,
    int? categoryId,
    String search = '',
    double? minPrice,
    double? maxPrice,
    Set<int>? onlyIds,
    SortOption sort = SortOption.defaultOrder,
  }) async {
    if (onlyIds != null && onlyIds.isEmpty) {
      return const ProductPage(items: [], totalCount: 0);
    }

    var query = _client.from(_table).select(_select);

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (onlyIds != null) query = query.inFilter('id', onlyIds.toList());
    final term = search.trim();
    if (term.isNotEmpty) {
      final escaped = term
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      query = query.ilike('name', '%$escaped%');
    }
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    final sorted = switch (sort) {
      SortOption.defaultOrder => query.order('id', ascending: true),
      SortOption.priceLowHigh =>
        query.order('price', ascending: true).order('id', ascending: true),
      SortOption.priceHighLow =>
        query.order('price', ascending: false).order('id', ascending: true),
    };

    final from = page * pageSize;
    final response = await sorted
        .range(from, from + pageSize - 1)
        .count(CountOption.exact);

    return ProductPage(
      items: response.data.map(Product.fromMap).toList(),
      totalCount: response.count,
    );
  }

  Future<({double min, double max})> fetchPriceBounds() async {
    final results = await Future.wait<Map<String, dynamic>?>([
      _client
          .from(_table)
          .select('price')
          .order('price', ascending: true)
          .limit(1)
          .maybeSingle(),
      _client
          .from(_table)
          .select('price')
          .order('price', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);
    return (
      min: ((results[0]?['price'] as num?) ?? 0).toDouble(),
      max: ((results[1]?['price'] as num?) ?? 0).toDouble(),
    );
  }

  Future<Product?> fetchById(int id) async {
    final row = await _client
        .from(_table)
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Product.fromMap(row);
  }

  Future<Product> create(ProductDraft draft) async {
    final row = await _client
        .from(_table)
        .insert(draft.toMap())
        .select(_select)
        .single();
    return Product.fromMap(row);
  }

  Future<Product> update(int id, ProductDraft draft) async {
    final row = await _client
        .from(_table)
        .update(draft.toMap())
        .eq('id', id)
        .select(_select)
        .maybeSingle();
    if (row == null) {
      throw const AppException(
        "You don't have permission to edit this product, or it no longer exists.",
        permissionDenied: true,
      );
    }
    return Product.fromMap(row);
  }

  Future<void> delete(int id) async {
    final deleted = await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) {
      throw const AppException(
        "You don't have permission to delete this product, or it no longer exists.",
        permissionDenied: true,
      );
    }
  }
}
