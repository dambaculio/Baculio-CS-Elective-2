import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_card.dart';

/// Responsive grid of [PokemonCard]s, built as a sliver so only the cards on
/// screen are built and the grid scrolls under the fixed header.
///
/// Uses a max tile width instead of a fixed column count, so the number of
/// columns adapts: 2 on phones, 3-4 on tablets, 5+ on desktop. Every card has
/// the same portrait ratio, like real trading cards.
class PokemonSliverGrid extends StatelessWidget {
  final List<Pokemon> pokemon;

  const PokemonSliverGrid({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.crossAxisExtent < 600;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isCompact ? 190 : 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: pokemon.length,
            itemBuilder: (context, index) => PokemonCard(
              key: ValueKey(pokemon[index].id),
              pokemon: pokemon[index],
            ),
          ),
        );
      },
    );
  }
}
