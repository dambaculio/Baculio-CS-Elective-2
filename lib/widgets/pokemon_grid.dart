import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_card.dart';

/// Responsive, scrollable grid of [PokemonCard]s.
///
/// Uses a max tile width instead of a fixed column count, so the number of
/// columns adapts automatically: ~2 on phones, 3–4 on tablets, 5+ on desktop.
class PokemonGrid extends StatelessWidget {
  final List<Pokemon> pokemon;

  const PokemonGrid({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return GridView.builder(
          // Lets pull-to-refresh work even when the grid fits on screen.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 20,
            8,
            isCompact ? 12 : 20,
            24,
          ),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isCompact ? 200 : 220,
            mainAxisSpacing: isCompact ? 10 : 16,
            crossAxisSpacing: isCompact ? 10 : 16,
            childAspectRatio: 0.82,
          ),
          itemCount: pokemon.length,
          itemBuilder: (context, index) => PokemonCard(
            key: ValueKey(pokemon[index].id),
            pokemon: pokemon[index],
          ),
        );
      },
    );
  }
}