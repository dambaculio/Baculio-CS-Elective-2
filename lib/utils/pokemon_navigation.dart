import 'package:flutter/material.dart';

import '../screens/pokemon_detail_screen.dart';

/// Opens the detail page of a Pokémon. Used by the grid cards and by the
/// tiles in the favorites panel.
void openPokemonDetail(BuildContext context, int pokemonId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PokemonDetailScreen(pokemonId: pokemonId),
    ),
  );
}
