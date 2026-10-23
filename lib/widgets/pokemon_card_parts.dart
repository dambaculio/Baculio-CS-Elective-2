import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../theme/pokemon_type_colors.dart';
import '../utils/pokemon_labels.dart';

/// Dark text color used on every card, so cards look the same everywhere.
const Color pokemonInk = Color(0xFF222222);

/// The favorite heart: a white round button that is always visible on top of
/// artwork. Filled red heart = favorite, grey outline = not a favorite.
/// Tapping it adds / removes the Pokémon, wherever the button is shown.
class FavoriteHeartButton extends ConsumerWidget {
  const FavoriteHeartButton({
    super.key,
    required this.pokemonId,
    this.size = 32,
  });

  final int pokemonId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite =
        ref.watch(favoritesProvider.select((ids) => ids.contains(pokemonId)));
    final label = isFavorite ? 'Remove from favorites' : 'Add to favorites';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isFavorite,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          elevation: 2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => ref.read(favoritesProvider.notifier).toggle(pokemonId),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: size * 0.6,
                color: isFavorite ? Colors.red.shade600 : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill with the Pokémon's main type, e.g. "GRASS".
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final String? type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        (type ?? 'basic').toUpperCase(),
        style: const TextStyle(
          color: pokemonInk,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Network image with its own loading and error states,
/// so one broken image never breaks the layout.
class PokemonImage extends StatelessWidget {
  const PokemonImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value:
                  total == null ? null : progress.cumulativeBytesLoaded / total,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.black45,
          size: 32,
        ),
      ),
    );
  }
}

/// The framed photo of a card: artwork, type badge (top-left) and favorite
/// heart (top-right). Used by the grid cards and the detail page.
/// Give it a height, or place it in an Expanded to fill the space.
class PokemonArtFrame extends StatelessWidget {
  const PokemonArtFrame({
    super.key,
    required this.pokemon,
    this.height,
    this.heartSize = 32,
  });

  final Pokemon pokemon;
  final double? height;
  final double heartSize;

  @override
  Widget build(BuildContext context) {
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.art,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: PokemonImage(url: pokemon.imageUrl),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: TypeBadge(type: pokemon.primaryType),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: FavoriteHeartButton(
                pokemonId: pokemon.id,
                size: heartSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The details area below the photo. It always carries the ORIGINAL name
/// (the card title is the nickname).
///
/// compact: two lines for grid cards. Otherwise: labeled rows for the
/// detail page.
class PokemonDetailsStrip extends StatelessWidget {
  const PokemonDetailsStrip({
    super.key,
    required this.pokemon,
    this.compact = true,
  });

  final Pokemon pokemon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
          : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: compact ? _compact() : _full(),
    );
  }

  Widget _compact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fit(
          Text(
            pokemon.displayName,
            style: const TextStyle(
              color: pokemonInk,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        _fit(
          Text(
            '${pokemon.cardNumber}  ·  HT ${pokemon.heightLabel}  ·  '
            'WT ${pokemon.weightLabel}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _full() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('Original name', pokemon.displayName),
        const SizedBox(height: 8),
        _row('Number', pokemon.formattedId),
        const SizedBox(height: 8),
        _row('Type', pokemon.typesLabel),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: pokemonInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  /// Shrinks the text a little instead of overflowing on narrow cards.
  Widget _fit(Widget child) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: child,
      );
}
