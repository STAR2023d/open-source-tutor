import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import 'data/profile_controller.dart';
import 'data/storage.dart';
import 'screens/grade_selector_screen.dart';
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
  late Future<ContentBundle> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent(widget.profile.grade);
  }

  Future<ContentBundle> _loadContent(String grade) async {
    // Delay loading slightly so the app shows a smooth loading state
    await Future.delayed(const Duration(milliseconds: 200));
    return loadContent(grade);
  }

  void _handleGradeChanged(String grade) {
    // Restart the content future so the app loads the correct grade.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _contentFuture = _loadContent(grade);
      });
    });
  }

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
            : _HomeContent(
                contentFuture: _contentFuture,
                store: widget.store,
                profile: widget.profile,
                onChangeGrade: _handleGradeChanged,
              ),
      ),
    );
  }
}

/// The main content screen, shown after onboarding.
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.contentFuture,
    required this.store,
    required this.profile,
    required this.onChangeGrade,
  });

  final Future<ContentBundle> contentFuture;
  final ProgressStore store;
  final ProfileController profile;
  final ValueChanged<String> onChangeGrade;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContentBundle>(
      future: contentFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hesabu'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Change grade',
                  icon: const Icon(Icons.language_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GradeSelectorScreen(
                          profile: profile,
                          initialGrade: profile.grade,
                          onGradeSelected: profile.setGrade,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: Text('Could not load lessons: ${snap.error}'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeScreen(
          content: snap.data!,
          store: store,
          theme: Theme.of(context),
          profile: profile,
        );
      },
    );
  }
}
