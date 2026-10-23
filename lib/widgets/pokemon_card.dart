import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../providers/nickname_provider.dart';
import '../theme/pokemon_type_colors.dart';
import '../utils/pokemon_navigation.dart';
import 'pokemon_card_parts.dart';

/// One card in the grid, laid out like a trading card:
///
///   ┌──────────────────────┐
///   │ Nickname (title)     │
///   │ ┌──────────────────┐ │
///   │ │ TYPE          ♥  │ │   photo, type badge, favorite heart
///   │ │     artwork      │ │
///   │ └──────────────────┘ │
///   │ Original name        │   details below the photo
///   │ NO. 007 · HT · WT    │
///   └──────────────────────┘
///
/// The title is the nickname. Without a nickname the card falls back to the
/// original name so it never has an empty title.
class PokemonCard extends ConsumerStatefulWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  ConsumerState<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends ConsumerState<PokemonCard> {
  bool _highlighted = false;

  void _setHighlighted(bool value) {
    if (_highlighted != value) setState(() => _highlighted = value);
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);

    // Only this card rebuilds when ITS nickname / favorite status changes.
    final nickname = ref.watch(nicknamesProvider.select((n) => n[pokemon.id]));
    final isFavorite =
        ref.watch(favoritesProvider.select((ids) => ids.contains(pokemon.id)));
    final title = nickname ?? pokemon.displayName;
    final typeText = pokemon.types.isEmpty
        ? ''
        : ', ${pokemon.types.join(' and ')} type';

    return Semantics(
      button: true,
      label: '$title, original name ${pokemon.displayName}, '
          'number ${pokemon.id}$typeText'
          '${isFavorite ? ', favorite' : ''}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHighlighted(true),
        onExit: (_) => _setHighlighted(false),
        child: GestureDetector(
          onTap: () => openPokemonDetail(context, pokemon.id),
          onTapDown: (_) => _setHighlighted(true),
          onTapUp: (_) => _setHighlighted(false),
          onTapCancel: () => _setHighlighted(false),
          child: AnimatedScale(
            scale: _highlighted ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border, width: 3),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _highlighted ? 0.28 : 0.16,
                    ),
                    blurRadius: _highlighted ? 14 : 6,
                    offset: Offset(0, _highlighted ? 6 : 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title = nickname
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: pokemonInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Photo (fills the remaining height)
                  Expanded(child: PokemonArtFrame(pokemon: pokemon)),
                  const SizedBox(height: 8),

                  // Details: original name, number, height, weight
                  PokemonDetailsStrip(pokemon: pokemon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
