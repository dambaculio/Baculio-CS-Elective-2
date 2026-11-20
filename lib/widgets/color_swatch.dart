import 'package:flutter/material.dart';

import '../theme/design_theme.dart';
import '../theme/product_colors.dart';

class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({
    super.key,
    required this.colorName,
    this.size = 34,
    this.selected = false,
    this.onTap,
  });

  final String colorName;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: swatchColorFor(colorName),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.hotPink : Colors.black26,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: size * 0.5,
              color:
                  ThemeData.estimateBrightnessForColor(
                        swatchColorFor(colorName),
                      ) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            )
          : null,
    );
    return Tooltip(
      message: colorName,
      child: onTap == null
          ? dot
          : InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: dot,
            ),
    );
  }
}
