import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_provider.dart';
import '../providers/pokemon_list_provider.dart';
import '../widgets/favorites_panel.dart';
import '../widgets/pokedex_logo.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/type_filter_bar.dart';

class PokedexScreen extends ConsumerWidget {
  /// Called when the user taps the light/dark toggle.
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const PokedexScreen({super.key, this.onThemeModeChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = ref.watch(pokemonListProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 150,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 2),
              child: Image.asset(
                'assets/images/PokeBall.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                semanticLabel: 'Pokéball',
              ),
            ),
            IconButton(
              tooltip: 'Reload',
              icon: list.isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              // Shows the loading screen and re-calls the SAME fetch() method.
              onPressed: list.isLoading
                  ? null
                  : () => ref.read(reloadScreenProvider.notifier).reload(),
            ),
          ],
        ),
        actions: [
          const FavoritesToggleButton(),
          if (onThemeModeChanged != null)
            ThemeToggle(
              isDark: isDark,
              onChanged: (dark) => onThemeModeChanged!(
                dark ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed at the top: it never scrolls and the panel opens BELOW it.
            const PokedexHeader(),
            const FavoritesPanel(),
            // Only this area scrolls.
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: const _PokedexContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexContent extends ConsumerWidget {
  const _PokedexContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pokemonListProvider);
    final pokemon = list.value;

    // Reload button tapped -> full loading screen until the fetch finishes.
    if (ref.watch(reloadScreenProvider)) return const LoadingView();

    // Data (including the previous data while refreshing) -> show it.
    if (pokemon != null) {
      if (pokemon.isEmpty) {
        return EmptyView(
          action: FilledButton.icon(
            onPressed: () => ref.read(reloadScreenProvider.notifier).reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        );
      }
      return const _LoadedPokedex();
    }

    // No data and not loading -> the request failed.
    if (list.hasError && !list.isLoading) {
      return ErrorView(
        message: '${list.error}',
        onRetry: () => ref.read(pokemonListProvider.notifier).fetch(),
      );
    }

    return const LoadingView();
  }
}

class _LoadedPokedex extends ConsumerWidget {
  const _LoadedPokedex();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total =
        ref.watch(pokemonListProvider.select((l) => l.value?.length ?? 0));
    final visible = ref.watch(visiblePokemonProvider);
    final types = ref.watch(availableTypesProvider);
    final filter = ref.watch(pokemonFilterProvider);
    final filterNotifier = ref.read(pokemonFilterProvider.notifier);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      // Pull-to-refresh also just re-calls fetch().
      onRefresh: () => ref.read(pokemonListProvider.notifier).fetch(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SearchField(),
                if (types.isNotEmpty)
                  TypeFilterBar(
                    types: types,
                    selected: filter.type,
                    onSelected: filterNotifier.setType,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          !filter.isActive
                              ? 'Showing $total Pokémon'
                              : 'Showing ${visible.length} of $total Pokémon',
                          style: text.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (filter.type != null)
                        TextButton.icon(
                          onPressed: filterNotifier.clearType,
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 18,
                          ),
                          label: const Text('Clear filter'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: EmptyView(
                title: 'No matches',
                subtitle: filter.query.isEmpty
                    ? 'No Pokémon match this type.'
                    : 'No Pokémon matches "${filter.query}".',
                action: OutlinedButton(
                  onPressed: filterNotifier.clearAll,
                  child: const Text('Clear filters'),
                ),
              ),
            )
          else
            PokemonSliverGrid(pokemon: visible),
        ],
      ),
    );
  }
}

/// Search box. Owns its TextEditingController (disposed below) and stays in
/// sync with the filter state, so "Clear filters" also empties the text.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(pokemonFilterProvider).query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(pokemonFilterProvider.select((f) => f.query));
    final notifier = ref.read(pokemonFilterProvider.notifier);

    ref.listen<String>(
      pokemonFilterProvider.select((f) => f.query),
      (_, next) {
        if (_controller.text != next) _controller.text = next;
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: notifier.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name, nickname or number',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    notifier.setQuery('');
                  },
                ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
