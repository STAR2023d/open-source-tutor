import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';
import 'format.dart';

enum PlaceValueMode { digits, counters }

/// Place-value chart for numbers up to 99,999.
///
/// Teaching use: Concrete -> Pictorial step for place value, total value and
/// reading/writing numbers. [counters] mode shows each digit as that many dots.
class PlaceValueChart extends StatelessWidget {
  const PlaceValueChart({
    super.key,
    required this.value,
    this.mode = PlaceValueMode.digits,
    this.showLabels = true,
    this.showValues = false,
    this.highlight = const {},
    this.minPlaces = 4,
  }) : assert(value >= 0 && value <= 99999);

  final int value;
  final PlaceValueMode mode;
  final bool showLabels;

  /// Show the total value (for example 7,000) under each digit.
  final bool showValues;

  /// Place names to highlight: ones, tens, hundreds, thousands, ten thousands.
  final Set<String> highlight;
  final int minPlaces;

  static const _names = ['ones', 'tens', 'hundreds', 'thousands', 'ten thousands'];
  static const _labels = ['Ones', 'Tens', 'Hundreds', 'Thousands', 'Ten\nthousands'];

  @override
  Widget build(BuildContext context) {
    final digits = value.toString();
    final places = min(5, max(minPlaces, digits.length));
    final scheme = Theme.of(context).colorScheme;
    final c = HesabuColors.of(context);
    final placeColors = [c.strandData, c.strandMeasurement, c.strandGeometry, c.strandNumbers, c.success];

    int? digitAt(int p) {
      final idx = digits.length - 1 - p;
      return idx >= 0 ? int.parse(digits[idx]) : null;
    }

    final spoken = [
      for (var p = places - 1; p >= 0; p--)
        if (digitAt(p) != null) '${digitAt(p)} ${_names[p]}',
    ].join(', ');

    return Semantics(
      label: 'Place value chart. ${formatNumber(value)} has $spoken.',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var p = places - 1; p >= 0; p--)
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: _PlaceColumn(
                    label: showLabels ? _labels[p] : null,
                    digit: digitAt(p),
                    place: p,
                    mode: mode,
                    showValue: showValues,
                    highlighted: highlight.contains(_names[p]),
                    color: placeColors[p],
                    scheme: scheme,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceColumn extends StatelessWidget {
  const _PlaceColumn({
    required this.label,
    required this.digit,
    required this.place,
    required this.mode,
    required this.showValue,
    required this.highlighted,
    required this.color,
    required this.scheme,
  });

  final String? label;
  final int? digit;
  final int place;
  final PlaceValueMode mode;
  final bool showValue;
  final bool highlighted;
  final Color color;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final border = highlighted ? scheme.primary : scheme.outline;
    final bg = highlighted ? scheme.primaryContainer : scheme.surfaceContainerLow;

    final Widget cell;
    if (mode == PlaceValueMode.digits) {
      cell = Center(
        child: Text(
          digit?.toString() ?? '',
          style: text.headlineMedium?.copyWith(
            color: highlighted ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      );
    } else {
      cell = Padding(
        padding: const EdgeInsets.all(Space.xs + 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < (digit ?? 0); i++)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          if (label != null)
            SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label!,
                      textAlign: TextAlign.center,
                      style: text.labelMedium?.copyWith(
                          color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500)),
                ),
              ),
            ),
          const SizedBox(height: Space.xs),
          Container(
            constraints: BoxConstraints(
              minHeight: mode == PlaceValueMode.digits ? 64 : 88,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Radii.control - 4),
              border: Border.all(color: border, width: highlighted ? 3 : 1.5),
            ),
            child: cell,
          ),
          if (showValue && digit != null) ...[
            const SizedBox(height: Space.xs),
            Text(formatNumber(digit! * pow(10, place).toInt()),
                style: text.labelMedium),
          ],
        ],
      ),
    );
  }
}
