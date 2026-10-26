import 'package:flutter/material.dart';

import 'hesabu_colors.dart';
import 'tokens.dart';

/// Brand seed. Everything in the Material scheme is derived from this.
const Color kSeed = Color(0xFF00897B);

/// Font family bundled with the app (see assets/fonts/README.md).
/// If the font files are not added, Flutter silently falls back to the
/// platform default, so the app still works.
const String kFontFamily = 'Lexend';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: kSeed, brightness: brightness);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
  );

  final t = base.textTheme;
  // Bigger and airier than Material defaults: these readers are 9-12 years old.
  final textTheme = t.copyWith(
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
    titleLarge: t.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
    titleMedium: t.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
    labelLarge: t.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: Radii.controlBr);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, kMinTapTarget),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, kMinTapTarget),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: Radii.controlBr,
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Radii.controlBr,
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.controlBr,
        borderSide: BorderSide(color: scheme.primary, width: 3),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      dark ? HesabuColors.dark : HesabuColors.light,
    ],
  );
}
