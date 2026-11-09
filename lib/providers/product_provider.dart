import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flower.dart';
import '../services/product_service.dart';

export '../services/product_service.dart' show SortOption;

enum ProductLoadState { idle, loading, success, error }

/// Single source of truth for the shop's product list.
///
/// The UI only changes filter/page values here; this class turns them
/// into ONE Supabase query (filters + order + range) and notifies the
/// widgets when the new page arrives.
class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductService? service})
    : _service = service ?? ProductService();

  final ProductService _service;

  /// Products per page (activity requires 6-8). 6 fills the 2- and
  /// 3-column grids evenly.
  static const int pageSize = 6;

  // ---------------- State ----------------
  ProductLoadState _state = ProductLoadState.idle;
  String? _errorMessage;
  List<Flower> _items = const [];
  int _totalCount = 0;
  int _page = 0; // zero-based

  // Filters
  String _category = 'All';
  String _search = '';
  SortOption _sort = SortOption.defaultOrder;
  Set<String> _favoriteIds = const {};

  // Price filter: [_priceBounds] are the slider limits (cheapest and most
  // expensive product), [_priceRange] is what the customer selected.
  RangeValues _priceBounds = const RangeValues(0, 0);
  RangeValues _priceRange = const RangeValues(0, 0);

  /// Products fetched so far, by id. Lets the detail page show a product
  /// instantly and pick up edits made from anywhere.
  final Map<String, Flower> _cache = {};

  Timer? _searchDebounce;

  /// Give up on a query that takes too long (bad connection) instead of
  /// leaving the spinner running forever.
  static const Duration _timeout = Duration(seconds: 10);

  /// Increases on every request; responses from older requests are
  /// ignored so a slow page can't overwrite a newer one.
  int _requestId = 0;

  // ---------------- Getters ----------------
  ProductLoadState get state => _state;
  bool get isLoading => _state == ProductLoadState.loading;
  String? get errorMessage => _errorMessage;
  List<Flower> get items => List.unmodifiable(_items);
  int get totalCount => _totalCount;
  int get page => _page;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / pageSize).ceil();
  bool get hasPrevious => _page > 0;
  bool get hasNext => _page < totalPages - 1;

  /// 1-based index of the first/last item shown, e.g. "7-12 of 26".
  int get firstItemNumber => _totalCount == 0 ? 0 : _page * pageSize + 1;
  int get lastItemNumber => _page * pageSize + _items.length;

  String get category => _category;
  String get search => _search;
  SortOption get sort => _sort;
  RangeValues get priceBounds => _priceBounds;
  RangeValues get priceRange => _priceRange;
  bool get hasPriceData => _priceBounds.end > _priceBounds.start;
  bool get isPriceFiltered =>
      _priceRange.start > _priceBounds.start ||
      _priceRange.end < _priceBounds.end;

  Flower? findById(String id) => _cache[id];

  // ---------------- Loading ----------------

  /// First load: get the slider limits, then page 1.
  Future<void> init() async {
    _state = ProductLoadState.loading;
    notifyListeners();
    try {
      await _loadPriceBounds(resetSelection: true);
    } catch (_) {
      // Bounds are optional; fetchPage below will surface real errors.
    }
    await fetchPage();
  }

  /// Runs the Supabase query for the current filters and [_page].
  Future<void> fetchPage() async {
    final requestId = ++_requestId;
    _state = ProductLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.fetchPage(
        page: _page,
        pageSize: pageSize,
        category: _category,
        search: _search,
        minPrice: hasPriceData ? _priceRange.start : null,
        maxPrice: hasPriceData ? _priceRange.end : null,
        onlyIds: _category == 'Favorites' ? _favoriteIds : null,
        sort: _sort,
      ).timeout(_timeout);
      if (requestId != _requestId) return; // a newer request won

      // If the current page no longer exists (e.g. last item on the last
      // page was deleted), step back to the real last page.
      if (result.items.isEmpty && result.totalCount > 0 && _page > 0) {
        _page = ((result.totalCount - 1) / pageSize).floor();
        await fetchPage();
        return;
      }

      _items = result.items;
      _totalCount = result.totalCount;
      for (final f in _items) {
        _cache[f.id] = f;
      }
      _state = ProductLoadState.success;
    } on TimeoutException {
      if (requestId != _requestId) return;
      _errorMessage = 'The request timed out. Check your connection.';
      _state = ProductLoadState.error;
    } on PostgrestException catch (error) {
      if (requestId != _requestId) return;
      // PGRST103 = asked for a page past the end (e.g. after deleting the
      // only item on the last page). Jump back to page 1 instead of
      // showing an error.
      if (error.code == 'PGRST103' && _page > 0) {
        _page = 0;
        await fetchPage();
        return;
      }
      _errorMessage = error.message;
      _state = ProductLoadState.error;
    } catch (error) {
      if (requestId != _requestId) return;
      _errorMessage = error.toString();
      _state = ProductLoadState.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _loadPriceBounds(resetSelection: false);
    } catch (_) {}
    await fetchPage();
  }

  Future<void> _loadPriceBounds({required bool resetSelection}) async {
    final bounds = await _service.fetchPriceBounds().timeout(_timeout);
    final newBounds = RangeValues(
      bounds.min.floorToDouble(),
      bounds.max.ceilToDouble(),
    );
    final wasFullRange = !isPriceFiltered;
    _priceBounds = newBounds;
    if (resetSelection || wasFullRange) {
      _priceRange = newBounds;
    } else {
      // Keep the customer's selection, but inside the new limits.
      final start = _priceRange.start
          .clamp(newBounds.start, newBounds.end)
          .toDouble();
      final end = _priceRange.end.clamp(start, newBounds.end).toDouble();
      _priceRange = RangeValues(start, end);
    }
  }

  /// Loads one product (detail page opened before the list had it).
  Future<Flower?> loadProduct(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final product = await _service.fetchById(id);
    if (product != null) {
      _cache[id] = product;
      notifyListeners();
    }
    return product;
  }

  // ---------------- Filters (each resets to page 1) ----------------

  void setCategory(String value) {
    if (_category == value) return;
    _category = value;
    _page = 0;
    fetchPage();
  }

  /// Search is debounced so we query once the user pauses typing.
  void setSearch(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _page = 0;
      fetchPage();
    });
  }

  void setSort(SortOption value) {
    if (_sort == value) return;
    _sort = value;
    _page = 0;
    fetchPage();
  }

  /// Called when the customer lets go of the price slider.
  void setPriceRange(RangeValues value) {
    if (value == _priceRange) return;
    _priceRange = value;
    _page = 0;
    fetchPage();
  }

  void resetPriceRange() => setPriceRange(_priceBounds);

  /// Favorites live in app state (main.dart); the provider needs them to
  /// query the Favorites tab.
  void setFavoriteIds(Set<String> ids) {
    _favoriteIds = Set.of(ids);
    if (_category == 'Favorites') fetchPage();
  }

  // ---------------- Pagination ----------------

  void goToPage(int page) {
    final target = page.clamp(0, totalPages - 1).toInt();
    if (target == _page) return;
    _page = target;
    fetchPage();
  }

  void nextPage() => goToPage(_page + 1);
  void previousPage() => goToPage(_page - 1);

  // ---------------- Update & Delete ----------------

  /// Saves changes to Supabase, then updates the cache and refetches so
  /// the product moves/disappears correctly if it no longer matches the
  /// active filters (e.g. its new price is outside the slider range).
  Future<void> updateProduct(String id, Map<String, dynamic> changes) async {
    final updated = await _service.updateProduct(id, changes);
    _cache[id] = updated;
    notifyListeners();
    await refresh();
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    _cache.remove(id);
    _favoriteIds = Set.of(_favoriteIds)..remove(id);
    await refresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
