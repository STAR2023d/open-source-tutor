import 'package:flutter/widgets.dart';
import 'package:mastery_core/mastery_core.dart';

import 'array_grid.dart';
import 'bar_model.dart';
import 'column_addition.dart';
import 'fraction_visual.dart';
import 'number_line.dart';
import 'place_value_chart.dart';

export 'array_grid.dart';
export 'bar_model.dart';
export 'column_addition.dart';
export 'fraction_visual.dart';
export 'number_line.dart';
export 'place_value_chart.dart';

/// Turns a [VisualSpec] from content JSON into a widget.
/// Returns null for unknown types so one bad visual never crashes a lesson
/// (tools/validate_content.py catches them in CI).
/// Keep the supported types in sync with VISUALS in tools/validate_content.py.
Widget? buildVisual(VisualSpec spec) {
  final p = spec.params;
  int i(String k, [int d = 0]) => (p[k] as num?)?.toInt() ?? d;
  double d(String k, [double def = 0]) => (p[k] as num?)?.toDouble() ?? def;
  bool b(String k, bool def) => p[k] as bool? ?? def;

  try {
    switch (spec.type) {
      case 'placeValueChart':
        return PlaceValueChart(
          value: i('value'),
          mode: p['mode'] == 'counters' ? PlaceValueMode.counters : PlaceValueMode.digits,
          showLabels: b('showLabels', true),
          showValues: b('showValues', false),
          highlight: ((p['highlight'] as List<dynamic>?) ?? const []).cast<String>().toSet(),
          minPlaces: i('minPlaces', 4),
        );
      case 'columnAddition':
        return ColumnAddition(
          a: i('a'),
          b: i('b'),
          showCarries: b('showCarries', false),
          showResult: b('showResult', false),
        );
      case 'barModel':
        return BarModel(
          parts: [
            for (final part in p['parts'] as List<dynamic>)
              BarPart(
                label: (part as Map<String, dynamic>)['label'] as String,
                value: part['value'] as String,
              ),
          ],
          total: p['total'] as String? ?? '?',
          totalLabel: p['totalLabel'] as String? ?? 'Total',
        );
      case 'numberLine':
        return NumberLine(
          min: d('min'),
          max: d('max', 10),
          step: d('step', 1),
          labelEvery: i('labelEvery', 1),
          marks: [
            for (final m in (p['marks'] as List<dynamic>?) ?? const [])
              NumberLineMark(
                ((m as Map<String, dynamic>)['value'] as num).toDouble(),
                label: m['label'] as String?,
              ),
          ],
        );
      case 'fractionBar':
        return FractionVisual(
          numerator: i('numerator'),
          denominator: i('denominator', 1),
          style: p['style'] == 'group' ? FractionStyle.group : FractionStyle.bar,
          showLabel: b('showLabel', true),
        );
      case 'arrayGrid':
        return ArrayGrid(
          rows: i('rows', 1),
          cols: i('cols', 1),
          showCounts: b('showCounts', true),
        );
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}
