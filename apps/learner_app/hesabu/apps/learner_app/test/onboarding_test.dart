import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_app/data/profile_controller.dart';
import 'package:learner_app/mascot/mascot.dart';
import 'package:learner_app/screens/onboarding_screen.dart';
import 'package:learner_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final profile = ProfileController(prefs);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    home: OnboardingScreen(profile: profile),
  ));
  return profile;
}

void main() {
  test('sanitizeNickname strips symbols and limits length', () {
    expect(sanitizeNickname('  Amina<script>  '), 'Aminascript');
    expect(sanitizeNickname("O'Brian-2"), "O'Brian-2");
    expect(sanitizeNickname('a' * 40).length, 16);
    expect(sanitizeNickname('A    B'), 'A B');
  });

  testWidgets('walks through three pages and saves buddy and nickname', (tester) async {
    final profile = await pumpOnboarding(tester);
    expect(find.textContaining('Jambo'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How Hesabu helps you learn'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose your maths buddy'), findsOneWidget);

    await tester.tap(find.text('Chui'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Amina');
    await tester.tap(find.text("Let's go!"));
    await tester.pump();

    expect(profile.onboarded, isTrue);
    expect(profile.nickname, 'Amina');
    expect(profile.mascot, MascotKind.chui);
  });

  testWidgets('skip uses friendly defaults', (tester) async {
    final profile = await pumpOnboarding(tester);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(profile.onboarded, isTrue);
    expect(profile.displayName, 'Champion');
    expect(profile.mascot, MascotKind.tembo);
  });

  testWidgets('replayWelcome clears the onboarded flag', (tester) async {
    SharedPreferences.setMockInitialValues({'profile.onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    final profile = ProfileController(prefs);
    expect(profile.onboarded, isTrue);
    await profile.replayWelcome();
    expect(profile.onboarded, isFalse);
  });
}
