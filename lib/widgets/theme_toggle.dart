import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sliding day/night switch. Yellow track + sun in light mode,
/// blue track + moon in dark mode.
class ThemeToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const ThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);
    final label = isDark ? 'Switch to light mode' : 'Switch to dark mode';

    return Semantics(
      button: true,
      toggled: isDark,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!isDark),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOut,
            width: 68,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.pokeBlue : AppTheme.pokeYellow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.pokeWhite, width: 2),
            ),
            child: Stack(
              children: [
                // Both icons sit behind the thumb
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            size: 14, color: Colors.white70),
                        Icon(Icons.nightlight_round,
                            size: 14, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                // Sliding thumb
                AnimatedAlign(
                  duration: duration,
                  curve: Curves.easeInOut,
                  alignment:
                      isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppTheme.pokeWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_rounded,
                      size: 16,
                      color: isDark ? AppTheme.pokeBlue : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}