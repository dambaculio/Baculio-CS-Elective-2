import 'package:flutter/material.dart';

/// Colors for one card.
class TypePalette {
  final Color base;
  final Color border;
  final List<Color> gradient;
  final List<Color> art;

  const TypePalette({
    required this.base,
    required this.border,
    required this.gradient,
    required this.art,
  });
}

/// One base color per Pokémon type. Cards and filter chips both read from
/// here, so changing a color updates both.
class PokemonTypeColors {
  PokemonTypeColors._();

  /// Insertion order is the order the filter chips appear in.
  static const Map<String, Color> _base = {
    'normal': Color(0xFFA8A77A),
    'fire': Color(0xFFEE8130),
    'water': Color(0xFF6390F0),
    'electric': Color(0xFFF7D02C),
    'grass': Color(0xFF7AC74C),
    'ice': Color(0xFF96D9D6),
    'fighting': Color(0xFFC22E28),
    'poison': Color(0xFFA33EA1),
    'ground': Color(0xFFE2BF65),
    'flying': Color(0xFFA98FF3),
    'psychic': Color(0xFFF95587),
    'bug': Color(0xFFA6B91A),
    'rock': Color(0xFFB6A136),
    'ghost': Color(0xFF735797),
    'dragon': Color(0xFF6F35FC),
    'dark': Color(0xFF705746),
    'steel': Color(0xFFB7B7CE),
    'fairy': Color(0xFFD685AD),
  };

  /// Used when a Pokémon's types could not be loaded.
  static const Color _fallback = Color(0xFFE8B923);

  /// Canonical type order (for sorting the chips).
  static List<String> get order => _base.keys.toList();

  static Color baseOf(String? type) => _base[type] ?? _fallback;

  static TypePalette paletteOf(String? type) {
    final base = baseOf(type);
    final hsl = HSLColor.fromColor(base);

    // Gradient stops are kept fairly light so dark text stays readable,
    // even on dark types like Ghost or Dragon.
    Color shade(double delta, double min, double max) => hsl
        .withLightness((hsl.lightness + delta).clamp(min, max).toDouble())
        .toColor();

    return TypePalette(
      base: base,
      border: shade(-0.12, 0.2, 0.9),
      gradient: [
        shade(0.30, 0.78, 0.92),
        shade(0.18, 0.62, 0.84),
        shade(0.08, 0.52, 0.78),
      ],
      art: [
        hsl.withLightness(0.95).toColor(),
        hsl.withLightness(0.82).toColor(),
      ],
    );
  }
}