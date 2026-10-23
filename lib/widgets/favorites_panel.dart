import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../providers/nickname_provider.dart';
import '../theme/pokemon_type_colors.dart';
import '../utils/pokemon_navigation.dart';
import 'pokemon_card_parts.dart';

/// AppBar button that expands / collapses the [FavoritesPanel].
/// A white pill with a heart and the number of favorites, so it stands out
/// on the red AppBar. The label is hidden on very narrow screens.
class FavoritesToggleButton extends ConsumerWidget {
  const FavoritesToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(favoritesPanelExpandedProvider);
    final count = ref.watch(favoritesProvider.select((ids) => ids.length));
    final showLabel = MediaQuery.sizeOf(context).width >= 420;
    final label = expanded ? 'Hide favorites' : 'Show favorites';

    final foreground = expanded ? Colors.red.shade700 : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: '$label, $count saved',
          excludeSemantics: true,
          child: Material(
            color:
                expanded ? Colors.white : Colors.white.withValues(alpha: 0.2),
            shape: const StadiumBorder(
              side: BorderSide(color: Colors.white70),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () =>
                  ref.read(favoritesPanelExpandedProvider.notifier).toggle(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      count > 0 || expanded
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: foreground,
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Favorites',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Retractable section that lists only the favorite Pokémon. It sits between
/// the fixed header and the scrolling content, so it can never cover the
/// header. It reads everything from Riverpod, so it always matches the hearts.
class FavoritesPanel extends ConsumerWidget {
  const FavoritesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(favoritesPanelExpandedProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: expanded
          ? const _PanelBody()
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

class _PanelBody extends ConsumerWidget {
  const _PanelBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritePokemonProvider);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Shorter tiles on short (e.g. landscape phone) screens.
    final tileHeight = MediaQuery.sizeOf(context).height < 500 ? 112.0 : 150.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, size: 20, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Favorites (${favorites.length})',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ref
                          .read(favoritesPanelExpandedProvider.notifier)
                          .collapse(),
                      icon: const Icon(Icons.keyboard_arrow_up),
                      label: const Text('Hide'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (favorites.isEmpty)
                  const _EmptyFavorites()
                else
                  SizedBox(
                    height: tileHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 8),
                      itemCount: favorites.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _FavoriteTile(pokemon: favorites[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 32, color: colors.outline),
          const SizedBox(height: 6),
          Text(
            'No favorites yet',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap the heart on a card to save it here.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A mini version of the grid card: photo with heart, nickname as the title,
/// original name below.
class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(nicknamesProvider.select((n) => n[pokemon.id]));
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openPokemonDetail(context, pokemon.id),
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border, width: 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: PokemonImage(url: pokemon.imageUrl),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FavoriteHeartButton(
                        pokemonId: pokemon.id,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nickname ?? pokemon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: pokemonInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                pokemon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
