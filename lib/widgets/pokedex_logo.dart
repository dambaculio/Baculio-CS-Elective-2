import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pokéball drawn in code, colored from [AppTheme].
class PokeballIcon extends StatelessWidget {
  final double size;

  const PokeballIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PokeballPainter()),
      ),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final outline = r * 0.1;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));

    // Top (red) and bottom (white) halves
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      Paint()..color = AppTheme.pokedexRed,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      Paint()..color = AppTheme.pokeWhite,
    );

    // Black band
    canvas.drawRect(
      Rect.fromLTWH(0, c.dy - r * 0.1, size.width, r * 0.2),
      Paint()..color = AppTheme.pokeBlack,
    );

    // Shine
    canvas.drawOval(
      Rect.fromLTWH(r * 0.35, r * 0.25, r * 0.4, r * 0.25),
      Paint()..color = AppTheme.pokeWhite.withValues(alpha: 0.85),
    );
    canvas.restore();

    // Outer outline
    canvas.drawCircle(
      c,
      r - outline / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..color = AppTheme.pokeBlack,
    );

    // Center button
    canvas.drawCircle(c, r * 0.3, Paint()..color = AppTheme.pokeBlack);
    canvas.drawCircle(c, r * 0.19, Paint()..color = AppTheme.pokeWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "PokéDex" wordmark: yellow fill with a blue outline.
class PokedexWordmark extends StatelessWidget {
  final double fontSize;

  const PokedexWordmark({super.key, this.fontSize = 40});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
      height: 1,
    );

    return Semantics(
      label: 'Pokédex',
      excludeSemantics: true,
      child: Stack(
        children: [
          // Outline layer
          Text(
            'PokéDex',
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.2
                ..strokeJoin = StrokeJoin.round
                ..color = AppTheme.pokeBlue,
            ),
          ),
          // Fill layer
          Text('PokéDex', style: base.copyWith(color: AppTheme.pokeYellow)),
        ],
      ),
    );
  }
}

/// Space at the top of the screen: logo + short description.
class PokedexHeader extends StatelessWidget {
  const PokedexHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.pokedexRed,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'PokéDex',
            image: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/PokeDex.png',
                  height: 120,
                  fit: BoxFit.contain,
                  semanticLabel: 'PokéDex',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
