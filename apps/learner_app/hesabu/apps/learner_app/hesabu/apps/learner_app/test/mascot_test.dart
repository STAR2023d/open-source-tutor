import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_app/mascot/mascot.dart';
import 'package:learner_app/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('every buddy and mood paints in $brightness', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(brightness),
        home: Scaffold(
          body: Wrap(children: [
            for (final k in MascotKind.values)
              for (final m in MascotMood.values) Mascot(kind: k, mood: m, size: 80),
          ]),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(Mascot), findsNWidgets(
          MascotKind.values.length * MascotMood.values.length));
    });
  }

  testWidgets('mascot is described for screen readers', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: Mascot(kind: MascotKind.twiga, mood: MascotMood.cheer),
      ),
    ));
    expect(find.bySemanticsLabel('Twiga the giraffe, looking cheerful'),
        findsOneWidget);
  });
}
