import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flower.dart';

enum SortOption { defaultOrder, priceLowHigh, priceHighLow }

class ProductPage {
  final List<Flower> items;
  final int totalCount;

  const ProductPage({required this.items, required this.totalCount});
}

class ProductService {
  ProductService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'products';

  Future<ProductPage> fetchPage({
    required int page,
    required int pageSize,
    String category = 'All',
    String search = '',
    double? minPrice,
    double? maxPrice,
    Set<String>? onlyIds,
    SortOption sort = SortOption.defaultOrder,
  }) async {
    if (onlyIds != null && onlyIds.isEmpty) {
      return const ProductPage(items: [], totalCount: 0);
    }

    var query = _client.from(_table).select();

    if (category != 'All' && category != 'Favorites') {
      query = query.eq('category', category);
    }
    if (onlyIds != null) {
      query = query.inFilter('id', onlyIds.toList());
    }
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
      SortOption.defaultOrder => query.order('sort_order', ascending: true),
      SortOption.priceLowHigh => query.order('price', ascending: true),
      SortOption.priceHighLow => query.order('price', ascending: false),
    };
    final ordered = sorted.order('id', ascending: true);

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await ordered.range(from, to).count(CountOption.exact);

    return ProductPage(
      items: response.data.map(Flower.fromMap).toList(),
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
    final cheapest = results[0];
    final priciest = results[1];

    return (
      min: ((cheapest?['price'] as num?) ?? 0).toDouble(),
      max: ((priciest?['price'] as num?) ?? 0).toDouble(),
    );
  }

  Future<Flower?> fetchById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : Flower.fromMap(row);
  }

  Future<Flower> updateProduct(String id, Map<String, dynamic> changes) async {
    final row = await _client
        .from(_table)
        .update(changes)
        .eq('id', id)
        .select()
        .maybeSingle();
    if (row == null) {
      throw Exception(
        'Update failed: product not found or blocked by Row Level Security.',
      );
    }
    return Flower.fromMap(row);
  }

  Future<void> deleteProduct(String id) async {
    final deleted = await _client.from(_table).delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete failed: product not found or blocked by Row Level Security.',
      );
    }
  }
}
