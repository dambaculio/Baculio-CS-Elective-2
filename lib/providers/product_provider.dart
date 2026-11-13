import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flower.dart';
import '../services/product_service.dart';

export '../services/product_service.dart' show SortOption;

enum ProductLoadState { idle, loading, success, error }

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductService? service})
    : _service = service ?? ProductService();

  final ProductService _service;

  static const int pageSize = 6;
  static const Duration _timeout = Duration(seconds: 10);

  ProductLoadState _state = ProductLoadState.idle;
  String? _errorMessage;
  List<Flower> _items = const [];
  int _totalCount = 0;
  int _page = 0;

  String _category = 'All';
  String _search = '';
  SortOption _sort = SortOption.defaultOrder;
  Set<String> _favoriteIds = const {};

  RangeValues _priceBounds = const RangeValues(0, 0);
  RangeValues _priceRange = const RangeValues(0, 0);

  final Map<String, Flower> _cache = {};
  Timer? _searchDebounce;
  int _requestId = 0;

  ProductLoadState get state => _state;
  bool get isLoading => _state == ProductLoadState.loading;
  String? get errorMessage => _errorMessage;
  List<Flower> get items => List.unmodifiable(_items);
  int get totalCount => _totalCount;
  int get page => _page;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / pageSize).ceil();
  bool get hasPrevious => _page > 0;
  bool get hasNext => _page < totalPages - 1;

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

  Future<void> init() async {
    _state = ProductLoadState.loading;
    notifyListeners();
    await _tryLoadPriceBounds(resetSelection: true);
    await fetchPage();
  }

  Future<void> fetchPage() async {
    final requestId = ++_requestId;
    _state = ProductLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service
          .fetchPage(
            page: _page,
            pageSize: pageSize,
            category: _category,
            search: _search,
            minPrice: hasPriceData ? _priceRange.start : null,
            maxPrice: hasPriceData ? _priceRange.end : null,
            onlyIds: _category == 'Favorites' ? _favoriteIds : null,
            sort: _sort,
          )
          .timeout(_timeout);
      if (requestId != _requestId) return;

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
    await _tryLoadPriceBounds(resetSelection: false);
    await fetchPage();
  }

  Future<void> _tryLoadPriceBounds({required bool resetSelection}) async {
    try {
      await _loadPriceBounds(resetSelection: resetSelection);
    } catch (error) {
      debugPrint('Price range unavailable: $error');
    }
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
      final start = _priceRange.start
          .clamp(newBounds.start, newBounds.end)
          .toDouble();
      final end = _priceRange.end.clamp(start, newBounds.end).toDouble();
      _priceRange = RangeValues(start, end);
    }
  }

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

  void setCategory(String value) {
    if (_category == value) return;
    _category = value;
    _page = 0;
    fetchPage();
  }

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

  void setPriceRange(RangeValues value) {
    if (value == _priceRange) return;
    _priceRange = value;
    _page = 0;
    fetchPage();
  }

  void resetPriceRange() => setPriceRange(_priceBounds);

  void setFavoriteIds(Set<String> ids) {
    _favoriteIds = Set.of(ids);
    if (_category == 'Favorites') fetchPage();
  }

  void goToPage(int page) {
    final target = page.clamp(0, totalPages - 1).toInt();
    if (target == _page) return;
    _page = target;
    fetchPage();
  }

  void nextPage() => goToPage(_page + 1);
  void previousPage() => goToPage(_page - 1);

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
