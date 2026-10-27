import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_app/theme/app_theme.dart';
import 'package:learner_app/theme/hesabu_colors.dart';
import 'package:learner_app/widgets/choice_tile.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('theme builds with semantic colours ($brightness)', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(brightness),
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ));
      expect(HesabuColors.of(captured).strand('Numbers'), isA<Color>());
    });
  }

  testWidgets('ChoiceTile shows its text and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: ChoiceTile(
          label: 'A',
          text: 'Hundreds',
          state: ChoiceState.idle,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.text('Hundreds'));
    expect(taps, 1);
  });

  testWidgets('ChoiceTile cannot be tapped when answered', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: const Scaffold(
        body: ChoiceTile(
          label: 'B',
          text: 'Tens',
          state: ChoiceState.incorrect,
          onTap: null,
        ),
      ),
    ));
    await tester.tap(find.text('Tens'));
    expect(taps, 0);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
