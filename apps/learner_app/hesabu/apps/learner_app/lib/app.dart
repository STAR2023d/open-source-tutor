import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import 'data/profile_controller.dart';
import 'data/storage.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class HesabuApp extends StatefulWidget {
  const HesabuApp({
    super.key,
    required this.theme,
    required this.profile,
    required this.store,
  });

  final ThemeController theme;
  final ProfileController profile;
  final ProgressStore store;

  @override
  State<HesabuApp> createState() => _HesabuAppState();
}

class _HesabuAppState extends State<HesabuApp> {
  late final Future<ContentBundle> _content = loadContent('grade4');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.theme, widget.profile]),
      builder: (context, _) => MaterialApp(
        title: 'Hesabu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: widget.theme.mode,
        builder: (context, child) {
          // Respect the system text size, add our own "larger text" on top,
          // and clamp so layouts never break.
          final mq = MediaQuery.of(context);
          final scale =
              (mq.textScaler.scale(1.0) * widget.theme.extraTextScale)
                  .clamp(1.0, 2.0)
                  .toDouble();
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        },
        home: !widget.profile.onboarded
            ? OnboardingScreen(profile: widget.profile)
            : FutureBuilder<ContentBundle>(
          future: _content,
          builder: (context, snap) {
            if (snap.hasError) {
              return Scaffold(
                body: Center(child: Text('Could not load lessons: ${snap.error}')),
              );
            }
            if (!snap.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return HomeScreen(
              content: snap.data!,
              store: widget.store,
              theme: widget.theme,
              profile: widget.profile,
            );
          },
        ),
      ),
    );
  }
}
