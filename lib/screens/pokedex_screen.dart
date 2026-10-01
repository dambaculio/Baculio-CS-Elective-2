import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';

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

  List<Pokemon> _filter(List<Pokemon> all) {
    final q = _query.trim().toLowerCase().replaceFirst('#', '');
    if (q.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.displayName.toLowerCase().contains(q) ||
            p.id.toString() == int.tryParse(q)?.toString())
        .toList();
  }

  void _showWhyFuture() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline),
        title: const Text('Why a Future, not a Stream?'),
        content: const SingleChildScrollView(
          child: Text(
            'Loading the Pokédex is a single HTTP GET request. It produces '
            'exactly ONE result — the list of 30 Pokémon — and then it is done.\n\n'
            'Rule of thumb: one result → Future; many results over time → Stream '
            '(live chat, sensors, WebSockets).\n\n'
            'So the service returns Future<List<Pokemon>>, created once in '
            'initState() and consumed by a FutureBuilder that shows the '
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon),
            SizedBox(width: 10),
            Text('Pokédex', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          if (widget.onThemeModeChanged != null)
            IconButton(
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () => widget.onThemeModeChanged!(
                isDark ? ThemeMode.light : ThemeMode.dark,
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
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
        ),
      ),
    );
  }

  Widget _buildLoaded(List<Pokemon> all) {
    final visible = _filter(all);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            _query.isEmpty
                ? 'Showing ${all.length} Pokémon'
                : 'Showing ${visible.length} of ${all.length} Pokémon',
            style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(
                  title: 'No matches',
                  subtitle: 'No Pokémon matches "$_query".',
                  action: OutlinedButton(
                    onPressed: _clearSearch,
                    child: const Text('Clear search'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onPullToRefresh,
                  child: PokemonGrid(pokemon: visible),
                ),
        ),
      ],
    );
  }
}