import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import 'auth_providers.dart';
import 'favorites_provider.dart';
import 'service_providers.dart';

export '../services/product_service.dart' show SortOption;

const int productsPerPage = 6;

class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.favoritesOnly = false,
    this.search = '',
    this.sort = SortOption.defaultOrder,
    this.priceRange,
    this.page = 0,
  });

  final int? categoryId;
  final bool favoritesOnly;
  final String search;
  final SortOption sort;
  final RangeValues? priceRange;
  final int page;

  bool get showingAll => categoryId == null && !favoritesOnly;

  static const Object _keep = Object();

  ProductFilter copyWith({
    Object? categoryId = _keep,
    bool? favoritesOnly,
    String? search,
    SortOption? sort,
    Object? priceRange = _keep,
    int? page,
  }) => ProductFilter(
    categoryId: identical(categoryId, _keep)
        ? this.categoryId
        : categoryId as int?,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    search: search ?? this.search,
    sort: sort ?? this.sort,
    priceRange: identical(priceRange, _keep)
        ? this.priceRange
        : priceRange as RangeValues?,
    page: page ?? this.page,
  );
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  Timer? _searchDebounce;

  @override
  ProductFilter build() {
    ref.watch(currentUserIdProvider);
    ref.onDispose(() => _searchDebounce?.cancel());
    return const ProductFilter();
  }

  void setSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!ref.mounted || state.search == value) return;
      state = state.copyWith(search: value, page: 0);
    });
  }

  void showAll() =>
      state = state.copyWith(categoryId: null, favoritesOnly: false, page: 0);

  void selectCategory(int categoryId) => state = state.copyWith(
    categoryId: categoryId,
    favoritesOnly: false,
    page: 0,
  );

  void showFavorites() =>
      state = state.copyWith(categoryId: null, favoritesOnly: true, page: 0);

  void setSort(SortOption sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort, page: 0);
  }

  void setPriceRange(RangeValues? range) =>
      state = state.copyWith(priceRange: range, page: 0);

  void goToPage(int page) {
    if (page < 0 || page == state.page) return;
    state = state.copyWith(page: page);
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );

final productPageProvider = FutureProvider<ProductPage>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) {
    return const ProductPage(items: [], totalCount: 0);
  }
  final filter = ref.watch(productFilterProvider);
  final favorites = filter.favoritesOnly ? ref.watch(favoritesProvider) : null;
  final filterNotifier = ref.read(productFilterProvider.notifier);
  try {
    return await ref
        .watch(productServiceProvider)
        .fetchPage(
          page: filter.page,
          pageSize: productsPerPage,
          categoryId: filter.categoryId,
          search: filter.search,
          minPrice: filter.priceRange?.start,
          maxPrice: filter.priceRange?.end,
          onlyIds: favorites,
          sort: filter.sort,
        )
        .timeout(const Duration(seconds: 15));
  } on PostgrestException catch (error) {
    if (error.code == 'PGRST103' && filter.page > 0) {
      Future.microtask(() => filterNotifier.goToPage(0));
      return const ProductPage(items: [], totalCount: 0);
    }
    rethrow;
  }
}, retry: (_, _) => null);

final priceBoundsProvider = FutureProvider<RangeValues?>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return null;
  final service = ref.watch(productServiceProvider);
  final bounds = await service.fetchPriceBounds();
  final min = bounds.min.floorToDouble();
  final max = bounds.max.ceilToDouble();
  return max > min ? RangeValues(min, max) : null;
}, retry: (_, _) => null);

final productByIdProvider = FutureProvider.family<Product?, int>(
  (ref, id) => ref.watch(productServiceProvider).fetchById(id),
  retry: (_, _) => null,
);

class ProductAdmin {
  ProductAdmin(this._ref);

  final Ref _ref;

  Future<Product> save({
    int? productId,
    required ProductDraft draft,
    PickedImage? newImage,
  }) async {
    var toSave = draft;
    if (newImage != null) {
      final url = await _ref
          .read(storageServiceProvider)
          .uploadProductImage(newImage);
      toSave = draft.withImageUrl(url);
    }
    final service = _ref.read(productServiceProvider);
    final saved = productId == null
        ? await service.create(toSave)
        : await service.update(productId, toSave);
    _refresh();
    return saved;
  }

  Future<void> delete(Product product) async {
    await _ref.read(productServiceProvider).delete(product.id);
    _ref.read(favoritesProvider.notifier).remove(product.id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(productPageProvider);
    _ref.invalidate(priceBoundsProvider);
    _ref.invalidate(productByIdProvider);
  }
}

final productAdminProvider = Provider<ProductAdmin>((ref) => ProductAdmin(ref));
