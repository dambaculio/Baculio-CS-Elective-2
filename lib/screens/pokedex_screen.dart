import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../theme/pokemon_type_colors.dart';
import '../widgets/pokedex_logo.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/type_filter_bar.dart';

class PokedexScreen extends StatefulWidget {
  /// Optional so tests can inject a fake service.
  final PokemonService? service;

  /// Called when the user taps the light/dark toggle.
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const PokedexScreen({super.key, this.service, this.onThemeModeChanged});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late final PokemonService _service;
  late final bool _ownsService;

  /// Created ONCE in initState — never inline in build(), otherwise every
  /// rebuild (e.g. typing in the search box) would re-fetch (Module 04).
  late Future<List<Pokemon>> _pokemonFuture;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Selected type chip. null means "All".
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? PokemonService();
    _pokemonFuture = _service.fetchPokemon(limit: 30);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  /// Retry / refresh: assign a NEW Future inside setState so FutureBuilder
  /// goes back to `waiting` and runs again.
  void _reload() {
    if (!mounted) return;
    setState(() {
      _selectedType = null;
      _pokemonFuture = _service.fetchPokemon(limit: 30);
    });
  }

  /// Used by pull-to-refresh, which needs a Future to know when to stop.
  Future<void> _onPullToRefresh() async {
    _reload();
    try {
      await _pokemonFuture;
    } catch (_) {
      // The error is already shown by FutureBuilder's error state.
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedType = null;
    });
  }

  List<Pokemon> _filter(List<Pokemon> all) {
    final q = _query.trim().toLowerCase().replaceFirst('#', '');
    return all.where((p) {
      final matchesType =
          _selectedType == null || p.types.contains(_selectedType);
      final matchesQuery =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.displayName.toLowerCase().contains(q) ||
          p.id.toString() == int.tryParse(q)?.toString();
      return matchesType && matchesQuery;
    }).toList();
  }

  /// Types present in the loaded data, in canonical order.
  List<String> _typesIn(List<Pokemon> all) {
    final present = <String>{for (final p in all) ...p.types};
    final order = PokemonTypeColors.order;
    final sorted = present.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a);
        final ib = order.indexOf(b);
        return (ia == -1 ? order.length : ia).compareTo(
          ib == -1 ? order.length : ib,
        );
      });
    return sorted;
  }

  void _showWhyFuture() {
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

    return Scaffold(
      appBar: AppBar(
        // The logo lives in the header below, so no title here.
        leadingWidth: 150,
        leading: SizedBox(
          width: 150,
          child: Row(
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
                onPressed: _showWhyFuture,
              ),
              IconButton(
                tooltip: 'Reload',
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
              ),
            ],
          ),
        ),
        actions: [
          if (widget.onThemeModeChanged != null)
            ThemeToggle(
              isDark: isDark,
              onChanged: (dark) => widget.onThemeModeChanged!(
                dark ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Pokemon>>(
                    future: _pokemonFuture,
                    builder: (context, snapshot) {
                      // 1. Loading
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingView();
                      }

                      // 2. Error
                      if (snapshot.hasError) {
                        return ErrorView(
                          message: snapshot.error.toString(),
                          onRetry: _reload,
                        );
                      }

                      // 3. Empty (API returned nothing)
                      final all = snapshot.data ?? const <Pokemon>[];
                      if (all.isEmpty) {
                        return EmptyView(
                          action: FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reload'),
                          ),
                        );
                      }

                      // 4. Data
                      return _buildLoaded(all);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(List<Pokemon> all) {
    final visible = _filter(all);
    final types = _typesIn(all);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isFiltering = _query.isNotEmpty || _selectedType != null;

    return RefreshIndicator(
      onRefresh: _onPullToRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PokedexHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Only show type chips if the types actually loaded.
            if (types.isNotEmpty)
              TypeFilterBar(
                types: types,
                selected: _selectedType,
                onSelected: (type) => setState(() => _selectedType = type),
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
                    subtitle: _query.isEmpty
                        ? 'No Pokémon match this type.'
                        : 'No Pokémon matches "$_query".',
                    action: OutlinedButton(
                      onPressed: _clearFilters,
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
