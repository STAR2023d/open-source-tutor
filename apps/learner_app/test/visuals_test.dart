import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_app/theme/app_theme.dart';
import 'package:learner_app/visuals/format.dart';
import 'package:learner_app/visuals/visual_factory.dart';
import 'package:mastery_core/mastery_core.dart';

Widget host(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
      theme: buildTheme(b),
      home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
    );

void main() {
  test('formatNumber groups thousands', () {
    expect(formatNumber(5382), '5,382');
    expect(formatNumber(46052), '46,052');
    expect(formatNumber(999), '999');
    expect(formatNumber(0.25), '0.25');
  });

  for (final b in Brightness.values) {
    group('visuals render in $b', () {
      testWidgets('PlaceValueChart shows digits and labels', (tester) async {
        await tester.pumpWidget(host(const PlaceValueChart(value: 5382), b: b));
        for (final d in ['5', '3', '8', '2']) {
          expect(find.text(d), findsOneWidget);
        }
        expect(find.text('Hundreds'), findsOneWidget);
      });

      testWidgets('PlaceValueChart can hide labels', (tester) async {
        await tester.pumpWidget(
            host(const PlaceValueChart(value: 5382, showLabels: false), b: b));
        expect(find.text('Hundreds'), findsNothing);
      });

      testWidgets('ColumnAddition shows the result only when asked', (tester) async {
        await tester.pumpWidget(host(const ColumnAddition(a: 2487, b: 3596), b: b));
        // 2,487 + 3,596 = 6,083. The digit 0 appears only in the answer.
        expect(find.text('0'), findsNothing);
        await tester.pumpWidget(host(
            const ColumnAddition(a: 2487, b: 3596, showResult: true), b: b));
        await tester.pump();
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('BarModel shows labels, values and the unknown', (tester) async {
        await tester.pumpWidget(host(
            const BarModel(parts: [
              BarPart(label: 'Monday', value: '3,648'),
              BarPart(label: 'Tuesday', value: '2,975'),
            ]),
            b: b));
        expect(find.text('Monday'), findsOneWidget);
        expect(find.text('3,648'), findsOneWidget);
        expect(find.text('Total: ?'), findsOneWidget);
      });

      testWidgets('NumberLine paints without errors', (tester) async {
        await tester.pumpWidget(host(
            const NumberLine(
                min: 2750,
                max: 2760,
                step: 1,
                labelEvery: 5,
                marks: [NumberLineMark(2758)]),
            b: b));
        expect(tester.takeException(), isNull);
      });

      testWidgets('FractionVisual labels an improper fraction', (tester) async {
        await tester.pumpWidget(
            host(const FractionVisual(numerator: 7, denominator: 4), b: b));
        expect(find.text('7/4'), findsOneWidget);
      });

      testWidgets('ArrayGrid shows its counts', (tester) async {
        await tester.pumpWidget(host(const ArrayGrid(rows: 4, cols: 6), b: b));
        expect(find.text('6 columns'), findsOneWidget);
        expect(find.text('4 rows'), findsOneWidget);
      });
    });
  }

  group('buildVisual', () {
    test('builds known types and returns null for unknown ones', () {
      expect(
        buildVisual(const VisualSpec(
            type: 'placeValueChart', params: {'value': 5382})),
        isA<PlaceValueChart>(),
      );
      expect(buildVisual(const VisualSpec(type: 'doesNotExist')), isNull);
    });

    test('bad params never throw', () {
      expect(
        buildVisual(const VisualSpec(
            type: 'barModel', params: {'parts': 'not a list'})),
        isNull,
      );
    });
  });
}
