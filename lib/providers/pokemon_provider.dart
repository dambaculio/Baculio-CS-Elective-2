import 'package:flutter/foundation.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

enum PokemonLoadState { idle, loading, success, error }

class PokemonProvider extends ChangeNotifier {
  PokemonProvider({PokemonService? service})
      : _service = service ?? PokemonService(),
        _ownsService = service == null;

  final PokemonService _service;
  final bool _ownsService;

  PokemonLoadState _state = PokemonLoadState.idle;
  bool _isRefreshing = false;
  List<Pokemon> _pokemon = const [];
  String? _errorMessage;
  String _query = '';
  String? _selectedType;

  PokemonLoadState get state => _state;
  bool get isRefreshing => _isRefreshing;
  List<Pokemon> get pokemon => List.unmodifiable(_pokemon);
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedType => _selectedType;

  List<Pokemon> get visiblePokemon {
    final query = _query.trim().toLowerCase().replaceFirst('#', '');
    return _pokemon.where((pokemon) {
      final matchesType =
          _selectedType == null || pokemon.types.contains(_selectedType);
      final matchesQuery = query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.displayName.toLowerCase().contains(query) ||
          pokemon.id.toString() == int.tryParse(query)?.toString();
      return matchesType && matchesQuery;
    }).toList();
  }

  List<String> get availableTypes {
    final types = <String>{for (final pokemon in _pokemon) ...pokemon.types};
    return types.toList()..sort();
  }

  Pokemon? findById(int id) {
    for (final pokemon in _pokemon) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  Future<void> fetchPokemon({int limit = 30}) async {
    _isRefreshing = _state == PokemonLoadState.success;
    _state = PokemonLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _pokemon = await _service.fetchPokemon(limit: limit);
      _state = PokemonLoadState.success;
    } catch (error) {
      _pokemon = const [];
      _errorMessage = error.toString();
      _state = PokemonLoadState.error;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setSelectedType(String? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _selectedType = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }
}