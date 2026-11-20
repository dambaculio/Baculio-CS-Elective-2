import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const double shopMaxWidth = 1200;
const double formMaxWidth = 640;
const double listMaxWidth = 760;

double sidePadding(double screenWidth, {double maxWidth = shopMaxWidth}) =>
    math.max(16, (screenWidth - maxWidth) / 2);

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = listMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
