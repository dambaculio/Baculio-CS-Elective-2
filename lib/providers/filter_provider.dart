import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import 'nickname_provider.dart';
import 'pokemon_list_provider.dart';

/// The current search text and selected type (null = no type filter).
class PokemonFilter {
  const PokemonFilter({this.query = '', this.type});

  final String query;
  final String? type;

  bool get isActive => query.isNotEmpty || type != null;
}

class PokemonFilterNotifier extends Notifier<PokemonFilter> {
  @override
  PokemonFilter build() => const PokemonFilter();

  void setQuery(String value) {
    if (state.query == value) return;
    state = PokemonFilter(query: value, type: state.type);
  }

  void setType(String? type) {
    if (state.type == type) return;
    state = PokemonFilter(query: state.query, type: type);
  }

  /// Clears only the type filter.
  void clearType() => setType(null);

  /// Clears both the type filter and the search text.
  void clearAll() => state = const PokemonFilter();
}

final pokemonFilterProvider =
    NotifierProvider<PokemonFilterNotifier, PokemonFilter>(
  PokemonFilterNotifier.new,
);

/// Every type that appears in the loaded data (from the real API data).
final availableTypesProvider = Provider<List<String>>((ref) {
  final all = ref.watch(pokemonListProvider).value ?? const <Pokemon>[];
  final types = <String>{for (final pokemon in all) ...pokemon.types};
  return types.toList()..sort();
});

/// The Pokémon that match the type filter and the search text.
/// Search also matches nicknames.
final visiblePokemonProvider = Provider<List<Pokemon>>((ref) {
  final all = ref.watch(pokemonListProvider).value ?? const <Pokemon>[];
  final filter = ref.watch(pokemonFilterProvider);
  final nicknames = ref.watch(nicknamesProvider);

  final query = filter.query.trim().toLowerCase().replaceFirst('#', '');
  return all.where((pokemon) {
    final matchesType =
        filter.type == null || pokemon.types.contains(filter.type);
    final nickname = nicknames[pokemon.id]?.toLowerCase();
    final matchesQuery = query.isEmpty ||
        pokemon.name.toLowerCase().contains(query) ||
        pokemon.displayName.toLowerCase().contains(query) ||
        (nickname != null && nickname.contains(query)) ||
        pokemon.id.toString() == int.tryParse(query)?.toString();
    return matchesType && matchesQuery;
  }).toList();
});
