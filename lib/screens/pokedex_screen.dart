import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokemon_provider.dart';
import '../widgets/pokedex_logo.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/type_filter_bar.dart';

class PokedexScreen extends StatelessWidget {
  /// Called when the user taps the light/dark toggle.
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const PokedexScreen({super.key, this.onThemeModeChanged});

  void _showWhyFuture(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline),
        title: const Text('Why a Future, not a Stream?'),
        content: const SingleChildScrollView(
          child: Text(
            'Loading the Pokédex produces exactly ONE result — the list of '
            '30 Pokémon with their types — and then it is done.\n\n'
            'Rule of thumb: one result → Future; many results over time → Stream '
            '(live chat, sensors, WebSockets).\n\n'
            'Under the hood the service makes one list request, then 30 '
            'independent detail requests that run together with Future.wait(). '
            'The result is still a single Future<List<Pokemon>>, created once '
            'in initState() and consumed by a FutureBuilder that shows the '
            'loading, error, empty and data states.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PokemonProvider>();

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
              tooltip: 'Why a Future?',
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showWhyFuture(context),
            ),
            IconButton(
              tooltip: 'Reload',
              icon: provider.isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: provider.isRefreshing
                  ? null
                  : () => context.read<PokemonProvider>().fetchPokemon(),
            ),
          ],
        ),
        actions: [
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: const _PokedexContent(),
          ),
        ),
      ),
    );
  }
}

class _PokedexContent extends StatelessWidget {
  const _PokedexContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PokemonProvider>();

    switch (provider.state) {
      case PokemonLoadState.idle:
      case PokemonLoadState.loading:
        return const LoadingView();
      case PokemonLoadState.error:
        return ErrorView(
          message: provider.errorMessage ?? 'Unable to load Pokémon.',
          onRetry: () => context.read<PokemonProvider>().fetchPokemon(),
        );
      case PokemonLoadState.success:
        if (provider.pokemon.isEmpty) {
          return EmptyView(
            action: FilledButton.icon(
              onPressed: () => context.read<PokemonProvider>().fetchPokemon(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          );
        }
        return const _LoadedPokedex();
    }
  }
}

class _LoadedPokedex extends StatelessWidget {
  const _LoadedPokedex();

  Future<void> _refresh(BuildContext context) async {
    await context.read<PokemonProvider>().fetchPokemon();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PokemonProvider>();
    final all = provider.pokemon;
    final visible = provider.visiblePokemon;
    final isFiltering =
        provider.query.isNotEmpty || provider.selectedType != null;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PokedexHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: context.read<PokemonProvider>().setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or number',
                  prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                        onPressed: () =>
                          context.read<PokemonProvider>().setQuery(''),
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (provider.availableTypes.isNotEmpty)
              TypeFilterBar(
                types: provider.availableTypes,
                selected: provider.selectedType,
                onSelected:
                    context.read<PokemonProvider>().setSelectedType,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                !isFiltering
                    ? 'Showing ${all.length} Pokémon'
                    : 'Showing ${visible.length} of ${all.length} Pokémon',
                style: text.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            visible.isEmpty
                ? EmptyView(
                    title: 'No matches',
                    subtitle: provider.query.isEmpty
                        ? 'No Pokémon match this type.'
                        : 'No Pokémon matches "${provider.query}".',
                    action: OutlinedButton(
                      onPressed:
                          context.read<PokemonProvider>().clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  )
                : PokemonGrid(pokemon: visible),
          ],
        ),
      ),
    );
  }
}
