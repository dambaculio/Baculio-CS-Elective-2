import 'package:flutter/material.dart';

import '../theme/design_theme.dart';

class PriceFilter extends StatefulWidget {
  const PriceFilter({
    super.key,
    required this.bounds,
    required this.selected,
    required this.onChanged,
  });

  final RangeValues bounds;
  final RangeValues? selected;
  final ValueChanged<RangeValues?> onChanged;

  @override
  State<PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<PriceFilter> {
  RangeValues? _dragging;

  RangeValues _clamp(RangeValues values) {
    final start = values.start
        .clamp(widget.bounds.start, widget.bounds.end)
        .toDouble();
    final end = values.end.clamp(start, widget.bounds.end).toDouble();
    return RangeValues(start, end);
  }

  static String _peso(double value) => '₱${value.round()}';

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    final values = _clamp(_dragging ?? widget.selected ?? bounds);
    final isFiltered = widget.selected != null;
    final divisions = ((bounds.end - bounds.start) / 10).round().clamp(1, 1000);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Price: ${_peso(values.start)} – ${_peso(values.end)}',
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isFiltered)
                TextButton(
                  onPressed: () {
                    setState(() => _dragging = null);
                    widget.onChanged(null);
                  },
                  child: const Text('Reset'),
                ),
            ],
          ),
          RangeSlider(
            min: bounds.start,
            max: bounds.end,
            divisions: divisions,
            values: values,
            labels: RangeLabels(_peso(values.start), _peso(values.end)),
            activeColor: AppColors.hotPink,
            inactiveColor: AppColors.pink,
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              final rounded = RangeValues(
                v.start.roundToDouble(),
                v.end.roundToDouble(),
              );
              final full =
                  rounded.start <= bounds.start && rounded.end >= bounds.end;
              widget.onChanged(full ? null : rounded);
            },
          ),
        ],
      ),
    );
  }
}
