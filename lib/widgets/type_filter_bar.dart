import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../theme/pokemon_type_colors.dart';

/// Horizontally scrolling row of pill-shaped filter chips:
/// "All" plus one chip per type found in the loaded data.
/// The selected chip is filled with its color and shows a checkmark.
class TypeFilterBar extends StatelessWidget {
  final List<String> types;

  /// null means "All".
  final String? selected;
  final ValueChanged<String?> onSelected;

  const TypeFilterBar({
    super.key,
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _chip(
              context,
              label: 'All',
              color: primary,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final type = types[index - 1];
          return _chip(
            context,
            label: Pokemon.typeLabel(type),
            color: PokemonTypeColors.baseOf(type),
            isSelected: selected == type,
            // Tapping the active chip again goes back to "All".
            onTap: () => onSelected(selected == type ? null : type),
          );
        },
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final onColor =
        color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Center(
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        checkmarkColor: onColor,
        onSelected: (_) => onTap(),
        backgroundColor: color.withValues(alpha: 0.15),
        selectedColor: color,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Colors.transparent : color.withValues(alpha: 0.6),
          ),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? onColor : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}