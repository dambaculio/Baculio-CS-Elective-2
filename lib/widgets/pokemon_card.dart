import 'package:flutter/material.dart';

import '../models/pokemon.dart';

/// One tile in the grid: image, name and ID.
/// Lifts slightly on hover (web/desktop) or press (touch).
class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  bool _highlighted = false;

  void _setHighlighted(bool value) {
    if (_highlighted != value) setState(() => _highlighted = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pokemon = widget.pokemon;

    return Semantics(
      label: '${pokemon.displayName}, number ${pokemon.id}',
      child: MouseRegion(
        onEnter: (_) => _setHighlighted(true),
        onExit: (_) => _setHighlighted(false),
        child: GestureDetector(
          onTapDown: (_) => _setHighlighted(true),
          onTapUp: (_) => _setHighlighted(false),
          onTapCancel: () => _setHighlighted(false),
          child: AnimatedScale(
            scale: _highlighted ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Card(
              elevation: _highlighted ? 6 : 1,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pokemon.formattedId,
                          style: text.labelMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: _PokemonImage(url: pokemon.imageUrl),
                      ),
                    ),
                    Text(
                      pokemon.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

/// Network image with its own loading and error states,
/// so one broken image never breaks the whole grid.
class _PokemonImage extends StatelessWidget {
  final String url;

  const _PokemonImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colors.outline,
          size: 32,
        ),
      ),
    );
  }
}