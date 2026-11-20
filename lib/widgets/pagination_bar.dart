import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageSelected,
    this.enabled = true,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    const window = 5;
    var first = (page - window ~/ 2).clamp(0, totalPages - 1);
    final last = (first + window - 1).clamp(0, totalPages - 1);
    first = (last - window + 1).clamp(0, totalPages - 1);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: enabled && page > 0
              ? () => onPageSelected(page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (var i = first; i <= last; i++)
          SizedBox(
            width: 40,
            height: 40,
            child: i == page
                ? FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      disabledBackgroundColor: AppColors.hotPink,
                      disabledForegroundColor: Colors.white,
                    ),
                    child: Text('${i + 1}'),
                  )
                : OutlinedButton(
                    onPressed: enabled ? () => onPageSelected(i) : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      side: const BorderSide(color: AppColors.pink),
                    ),
                    child: Text('${i + 1}'),
                  ),
          ),
        IconButton(
          tooltip: 'Next page',
          onPressed: enabled && page < totalPages - 1
              ? () => onPageSelected(page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
