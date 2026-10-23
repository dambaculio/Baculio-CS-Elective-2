import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

/// Owns the [PokemonService] (and its HTTP client) for the whole app.
/// Tests can swap it with `pokemonServiceProvider.overrideWithValue(...)`.
final pokemonServiceProvider = Provider<PokemonService>((ref) {
  final service = PokemonService();
  ref.onDispose(service.dispose);
  return service;
});

/// Holds the Pokémon list and its loading / success / error state.
///
/// The state is an `AsyncValue<List<Pokemon>>`, which is Riverpod's built-in
/// way of representing the three UI states:
///   * AsyncLoading -> show the loading indicator
///   * AsyncData    -> show the grid
///   * AsyncError   -> show the error message + retry
class PokemonListNotifier extends AsyncNotifier<List<Pokemon>> {
  static const int _limit = 30;

  /// Runs once, the first time anything watches [pokemonListProvider].
  @override
  Future<List<Pokemon>> build() => _load();

  Future<List<Pokemon>> _load() =>
      ref.read(pokemonServiceProvider).fetchPokemon(limit: _limit);

  /// Fetches the list from the API. This is the ONE fetch method: the refresh
  /// button, pull-to-refresh and the "Try again" button all call it again.
  ///
  /// While it runs, the previous data (if any) is kept so the grid does not
  /// disappear during a refresh.
  Future<void> fetch() async {
    state = const AsyncLoading<List<Pokemon>>().copyWithPrevious(state);
    final result = await AsyncValue.guard(_load);
    if (!ref.mounted) return;
    state = result;
  }
}

final pokemonListProvider =
    AsyncNotifierProvider<PokemonListNotifier, List<Pokemon>>(
  PokemonListNotifier.new,
  // Riverpod 3 retries failed providers automatically. We want the error
  // state to show immediately, with our own "Try again" button instead.
  retry: (_, _) => null,
);

/// Looks up one Pokémon by id from the loaded list (used by the detail page).
final pokemonByIdProvider = Provider.family<Pokemon?, int>((ref, id) {
  final all = ref.watch(pokemonListProvider).value ?? const <Pokemon>[];
  for (final pokemon in all) {
    if (pokemon.id == id) return pokemon;
  }
  return null;
});

/// True while the full-screen loading view should be shown after the user
/// taps the reload button. (Pull-to-refresh keeps using its own spinner.)
class ReloadScreenNotifier extends Notifier<bool> {
  /// Keeps the loading view up at least this long so a fast reload doesn't
  /// just flicker.
  static const Duration _minimumDisplay = Duration(milliseconds: 400);

  @override
  bool build() => false;

  /// Shows the loading screen and re-calls the notifier's fetch().
  Future<void> reload() async {
    if (state) return;
    state = true;
    try {
      await Future.wait([
        ref.read(pokemonListProvider.notifier).fetch(),
        Future<void>.delayed(_minimumDisplay),
      ]);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final reloadScreenProvider =
    NotifierProvider<ReloadScreenNotifier, bool>(ReloadScreenNotifier.new);
