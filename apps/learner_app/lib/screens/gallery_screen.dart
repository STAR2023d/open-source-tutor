import 'package:flutter/material.dart';

import '../mascot/mascot.dart';
import '../theme/tokens.dart';
import '../visuals/visual_factory.dart';
import '../widgets/visual_card.dart';

/// Every teaching picture with sample data. Used to review looks in light and
/// dark mode and to show contributors what they can put in a question's
/// `visual` field (see docs/visuals.md).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget section(String title, String json, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              const SizedBox(height: Space.xs),
              SelectableText(json,
                  style: text.bodyMedium?.copyWith(fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: Space.s),
              VisualCard(title: title, child: child),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Picture gallery')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(Space.m),
            children: [
              section(
                'Buddies and moods',
                'Mascot(kind: MascotKind.tembo, mood: MascotMood.cheer)',
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final k in MascotKind.values)
                      for (final m in MascotMood.values)
                        Mascot(kind: k, mood: m, size: 76),
                  ],
                ),
              ),
              section(
                'Place value chart',
                '{"type":"placeValueChart","value":27450,"highlight":["thousands"],"showValues":true}',
                const PlaceValueChart(
                  value: 27450,
                  highlight: {'thousands'},
                  showValues: true,
                ),
              ),
              section(
                'Place value counters',
                '{"type":"placeValueChart","value":3406,"mode":"counters"}',
                const PlaceValueChart(value: 3406, mode: PlaceValueMode.counters),
              ),
              section(
                'Column addition',
                '{"type":"columnAddition","a":3648,"b":2975,"showCarries":true,"showResult":true}',
                const ColumnAddition(a: 3648, b: 2975, showCarries: true, showResult: true),
              ),
              section(
                'Bar model',
                '{"type":"barModel","parts":[{"label":"Monday","value":"3,648"},{"label":"Tuesday","value":"2,975"}],"total":"?"}',
                const BarModel(parts: [
                  BarPart(label: 'Monday', value: '3,648'),
                  BarPart(label: 'Tuesday', value: '2,975'),
                ]),
              ),
              section(
                'Number line',
                '{"type":"numberLine","min":2750,"max":2760,"step":1,"labelEvery":5,"marks":[{"value":2758}]}',
                const NumberLine(
                  min: 2750,
                  max: 2760,
                  step: 1,
                  labelEvery: 5,
                  marks: [NumberLineMark(2758, label: '2,758')],
                ),
              ),
              section(
                'Fraction bar (improper fraction)',
                '{"type":"fractionBar","numerator":7,"denominator":4}',
                const FractionVisual(numerator: 7, denominator: 4),
              ),
              section(
                'Fraction of a group',
                '{"type":"fractionBar","numerator":3,"denominator":8,"style":"group"}',
                const FractionVisual(
                    numerator: 3, denominator: 8, style: FractionStyle.group),
              ),
              section(
                'Array grid (multiplication and area)',
                '{"type":"arrayGrid","rows":4,"cols":6}',
                const ArrayGrid(rows: 4, cols: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
