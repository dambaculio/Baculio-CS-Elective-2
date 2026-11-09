import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flower.dart';

/// How the product list is ordered.
enum SortOption { defaultOrder, priceLowHigh, priceHighLow }

/// One page of products plus the total number of rows that match the
/// current filters (needed to know how many pages there are).
class ProductPage {
  final List<Flower> items;
  final int totalCount;

  const ProductPage({required this.items, required this.totalCount});
}

/// Every Supabase call for the `products` table lives here, so the
/// provider and the widgets never build queries themselves.
class ProductService {
  ProductService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'products';

  /// Fetches ONE page of products. All filtering, sorting and paging is
  /// done by Postgres, so only [pageSize] rows travel over the network.
  ///
  /// Query order follows the class cheat sheet:
  ///   1. filters  (.eq / .ilike / .gte / .lte / .inFilter)
  ///   2. ordering (.order)
  ///   3. paging   (.range)
  Future<ProductPage> fetchPage({
    required int page, // zero-based
    required int pageSize,
    String category = 'All',
    String search = '',
    double? minPrice,
    double? maxPrice,
    Set<String>? onlyIds, // used by the Favorites tab
    SortOption sort = SortOption.defaultOrder,
  }) async {
    // Favorites tab with no favorites: nothing to ask the server for.
    if (onlyIds != null && onlyIds.isEmpty) {
      return const ProductPage(items: [], totalCount: 0);
    }

    // 1. Filters
    var query = _client.from(_table).select();

    if (category != 'All' && category != 'Favorites') {
      query = query.eq('category', category);
    }
    if (onlyIds != null) {
      query = query.inFilter('id', onlyIds.toList());
    }
    final term = search.trim();
    if (term.isNotEmpty) {
      // Case-insensitive "contains". Escape % and _ so they are matched
      // literally instead of acting as SQL wildcards.
      final escaped = term
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      query = query.ilike('name', '%$escaped%');
    }
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    // 2. Ordering. `id` is a tie-breaker so items with the same price
    //    never swap places between pages.
    final sorted = switch (sort) {
      SortOption.defaultOrder => query.order('sort_order', ascending: true),
      SortOption.priceLowHigh => query.order('price', ascending: true),
      SortOption.priceHighLow => query.order('price', ascending: false),
    };
    final ordered = sorted.order('id', ascending: true);

    // 3. Paging. .range() is zero-based and inclusive on both ends,
    //    e.g. page 0 with size 6 -> range(0, 5).
    final from = page * pageSize;
    final to = from + pageSize - 1;

    // .count() makes Postgres also return the total number of matching
    // rows (ignoring the range), so we can compute the page count.
    final response = await ordered.range(from, to).count(CountOption.exact);

    return ProductPage(
      items: response.data.map(Flower.fromMap).toList(),
      totalCount: response.count,
    );
  }

  /// Cheapest and most expensive price in the table; used as the
  /// limits of the price slider.
  Future<({double min, double max})> fetchPriceBounds() async {
    // The two queries don't depend on each other, so run them at the
    // same time with Future.wait instead of awaiting one after the other.
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

  /// Single product, e.g. when the detail page is opened directly.
  Future<Flower?> fetchById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : Flower.fromMap(row);
  }

  /// Updates the given columns of one product and returns the new row.
  /// Always filtered with .eq('id', ...) so only that product changes.
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

  /// Deletes one product. .select() returns the deleted rows, so an empty
  /// result means nothing was deleted (wrong id or RLS policy missing).
  Future<void> deleteProduct(String id) async {
    final deleted = await _client.from(_table).delete().eq('id', id).select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete failed: product not found or blocked by Row Level Security.',
      );
    }
  }
}
