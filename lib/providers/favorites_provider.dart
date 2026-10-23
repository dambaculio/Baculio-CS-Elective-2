import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import 'pokemon_list_provider.dart';

/// The ids of the favorite Pokémon, in the order they were favorited.
class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const <int>{};

  void add(int id) {
    if (state.contains(id)) return;
    state = <int>{...state, id};
  }

  void remove(int id) {
    if (!state.contains(id)) return;
    state = <int>{...state}..remove(id);
  }

  /// Heart tapped: add if missing, remove if present.
  void toggle(int id) => state.contains(id) ? remove(id) : add(id);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);

/// The full [Pokemon] objects for the favorite ids. Recomputed automatically
/// whenever the favorites or the loaded list change, so the panel always
/// matches the hearts.
final favoritePokemonProvider = Provider<List<Pokemon>>((ref) {
  final ids = ref.watch(favoritesProvider);
  final all = ref.watch(pokemonListProvider).value ?? const <Pokemon>[];
  final byId = {for (final pokemon in all) pokemon.id: pokemon};
  return [
    for (final id in ids)
      if (byId.containsKey(id)) byId[id]!,
  ];
});

/// Whether the favorites panel is expanded. Lives in app state (not in a
/// widget) so it stays the same while moving between screens.
class FavoritesPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void collapse() => state = false;
}

final favoritesPanelExpandedProvider =
    NotifierProvider<FavoritesPanelNotifier, bool>(FavoritesPanelNotifier.new);
