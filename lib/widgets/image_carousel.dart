import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

/// StatefulWidget
class ImageCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final double? height;

  const ImageCarousel({
    super.key,
    required this.imagePaths,
    this.height,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // Auto-advance every 4 seconds, looping back to the start.
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.imagePaths.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.imagePaths.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final heightRatio = width < 600
              ? 0.86
              : width < 840
                ? 0.48
                : 0.36;
            final carouselHeight = widget.height ??
              math.min(width * heightRatio, width < 600 ? 360 : 380);

            return SizedBox(
              height: carouselHeight,
              child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.imagePaths[index],
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.lightPink,
                      alignment: Alignment.center,
                      child: const Icon(Icons.local_florist_outlined, size: 48),
                    ),
                  ),
                ),
              );
            },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Dot indicators showing which slide is active.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imagePaths.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.hotPink : AppColors.pink,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}