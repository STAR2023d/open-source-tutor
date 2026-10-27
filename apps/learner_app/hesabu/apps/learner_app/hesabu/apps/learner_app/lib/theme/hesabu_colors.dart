import 'package:flutter/material.dart';

/// Semantic colours that Material's ColorScheme does not have.
///
/// Design rule: a wrong answer is amber ("try again"), never red. Red feels
/// like punishment; amber says "not yet". Colour is never the only signal:
/// every state also has an icon and a word.
@immutable
class HesabuColors extends ThemeExtension<HesabuColors> {
  const HesabuColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.tryAgain,
    required this.tryAgainContainer,
    required this.onTryAgainContainer,
    required this.hint,
    required this.hintContainer,
    required this.onHintContainer,
    required this.strandNumbers,
    required this.strandMeasurement,
    required this.strandGeometry,
    required this.strandData,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color tryAgain;
  final Color tryAgainContainer;
  final Color onTryAgainContainer;
  final Color hint;
  final Color hintContainer;
  final Color onHintContainer;
  final Color strandNumbers;
  final Color strandMeasurement;
  final Color strandGeometry;
  final Color strandData;

  static const light = HesabuColors(
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFDFF3E0),
    onSuccessContainer: Color(0xFF0B3D14),
    tryAgain: Color(0xFFB26A00),
    tryAgainContainer: Color(0xFFFFE9C7),
    onTryAgainContainer: Color(0xFF4A2C00),
    hint: Color(0xFF1565C0),
    hintContainer: Color(0xFFDCEBFF),
    onHintContainer: Color(0xFF0B2E5C),
    strandNumbers: Color(0xFF00796B),
    strandMeasurement: Color(0xFFE65100),
    strandGeometry: Color(0xFF6A1B9A),
    strandData: Color(0xFF1565C0),
  );

  static const dark = HesabuColors(
    success: Color(0xFF7FD68A),
    successContainer: Color(0xFF16391B),
    onSuccessContainer: Color(0xFFCFEFD3),
    tryAgain: Color(0xFFFFC66B),
    tryAgainContainer: Color(0xFF4A3000),
    onTryAgainContainer: Color(0xFFFFE2B0),
    hint: Color(0xFF9CC6FF),
    hintContainer: Color(0xFF12305A),
    onHintContainer: Color(0xFFD2E4FF),
    strandNumbers: Color(0xFF4DB6AC),
    strandMeasurement: Color(0xFFFFAB62),
    strandGeometry: Color(0xFFCE93D8),
    strandData: Color(0xFF90CAF9),
  );

  static HesabuColors of(BuildContext context) =>
      Theme.of(context).extension<HesabuColors>()!;

  /// Accent colour for a curriculum strand name as used in skills.json.
  Color strand(String name) => switch (name) {
        'Numbers' => strandNumbers,
        'Measurement' => strandMeasurement,
        'Geometry' => strandGeometry,
        _ => strandData,
      };

  IconData strandIcon(String name) => switch (name) {
        'Numbers' => Icons.numbers,
        'Measurement' => Icons.straighten,
        'Geometry' => Icons.interests,
        _ => Icons.bar_chart,
      };

  @override
  HesabuColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? tryAgain,
    Color? tryAgainContainer,
    Color? onTryAgainContainer,
    Color? hint,
    Color? hintContainer,
    Color? onHintContainer,
    Color? strandNumbers,
    Color? strandMeasurement,
    Color? strandGeometry,
    Color? strandData,
  }) =>
      HesabuColors(
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        tryAgain: tryAgain ?? this.tryAgain,
        tryAgainContainer: tryAgainContainer ?? this.tryAgainContainer,
        onTryAgainContainer: onTryAgainContainer ?? this.onTryAgainContainer,
        hint: hint ?? this.hint,
        hintContainer: hintContainer ?? this.hintContainer,
        onHintContainer: onHintContainer ?? this.onHintContainer,
        strandNumbers: strandNumbers ?? this.strandNumbers,
        strandMeasurement: strandMeasurement ?? this.strandMeasurement,
        strandGeometry: strandGeometry ?? this.strandGeometry,
        strandData: strandData ?? this.strandData,
      );

  @override
  HesabuColors lerp(ThemeExtension<HesabuColors>? other, double t) {
    if (other is! HesabuColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return HesabuColors(
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      tryAgain: l(tryAgain, other.tryAgain),
      tryAgainContainer: l(tryAgainContainer, other.tryAgainContainer),
      onTryAgainContainer: l(onTryAgainContainer, other.onTryAgainContainer),
      hint: l(hint, other.hint),
      hintContainer: l(hintContainer, other.hintContainer),
      onHintContainer: l(onHintContainer, other.onHintContainer),
      strandNumbers: l(strandNumbers, other.strandNumbers),
      strandMeasurement: l(strandMeasurement, other.strandMeasurement),
      strandGeometry: l(strandGeometry, other.strandGeometry),
      strandData: l(strandData, other.strandData),
    );
  }
}
