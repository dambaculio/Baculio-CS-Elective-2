import '../models/pokemon.dart';

/// Small display helpers so every screen formats a Pokémon the same way.
extension PokemonLabels on Pokemon {
  /// "NO. 007"
  String get cardNumber => 'NO. ${id.toString().padLeft(3, '0')}';

  String get heightLabel =>
      height == null ? '—' : '${(height! / 10).toStringAsFixed(1)} m';

  String get weightLabel =>
      weight == null ? '—' : '${(weight! / 10).toStringAsFixed(1)} kg';

  /// "Grass / Poison", or "Unknown" when the types could not be loaded.
  String get typesLabel =>
      types.isEmpty ? 'Unknown' : types.map(Pokemon.typeLabel).join(' / ');
}
