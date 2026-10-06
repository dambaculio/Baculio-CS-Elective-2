import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../theme/pokemon_type_colors.dart';
import '../screens/pokemon_detail_screen.dart';

/// One tile in the grid, styled like a trading card and colored by the
/// Pokémon's primary type: type badge + name on top, artwork in a framed
/// box, and the Pokédex number once in the footer.
/// Lifts slightly on hover (web/desktop) or press (touch).
class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  bool _highlighted = false;

  static const Color _ink = Color(0xFF222222);

  void _setHighlighted(bool value) {
    if (_highlighted != value) setState(() => _highlighted = value);
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);
    final badgeText = (pokemon.primaryType ?? 'basic').toUpperCase();
    final secondary = pokemon.secondaryType;

    final typeSemantics = pokemon.types.isEmpty
        ? ''
        : ', ${pokemon.types.join(' and ')} type';

    return Semantics(
      label: '${pokemon.displayName}, number ${pokemon.id}$typeSemantics',
      child: MouseRegion(
        onEnter: (_) => _setHighlighted(true),
        onExit: (_) => _setHighlighted(false),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PokemonDetailScreen(pokemonId: pokemon.id),
            ),
          ),
          onTapDown: (_) => _setHighlighted(true),
          onTapUp: (_) => _setHighlighted(false),
          onTapCancel: () => _setHighlighted(false),
          child: AnimatedScale(
            scale: _highlighted ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border, width: 4),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _highlighted ? 0.35 : 0.2,
                    ),
                    blurRadius: _highlighted ? 12 : 5,
                    offset: Offset(0, _highlighted ? 6 : 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: type badge + name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pokemon.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Framed artwork
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: palette.border, width: 2.5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: palette.art,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: _PokemonImage(url: pokemon.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Footer: the ID appears ONLY here; second type (if any)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pokemon.formattedId,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (secondary != null)
                        Text(
                          Pokemon.typeLabel(secondary),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Network image with its own loading and error states,
/// so one broken image never breaks the whole grid.
class _PokemonImage extends StatelessWidget {
  final String url;

  const _PokemonImage({required this.url});

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
              value: total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total,
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