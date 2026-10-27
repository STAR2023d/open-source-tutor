import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum FractionStyle { bar, group }

/// Fraction as part of a whole (bars) or part of a group (counters).
/// Improper fractions such as 7/4 draw extra whole bars, which also
/// supports the improper-to-mixed conversion lesson.
class FractionVisual extends StatelessWidget {
  const FractionVisual({
    super.key,
    required this.numerator,
    required this.denominator,
    this.style = FractionStyle.bar,
    this.showLabel = true,
  })  : assert(denominator >= 1 && denominator <= 12),
        assert(numerator >= 0);

  final int numerator;
  final int denominator;
  final FractionStyle style;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final filledColor = scheme.primary;
    final emptyColor = scheme.surfaceContainerHigh;

    final Widget body;
    if (style == FractionStyle.bar) {
      final wholes = (numerator / denominator).ceil().clamp(1, 6);
      body = Column(
        children: [
          for (var k = 0; k < wholes; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Row(
                children: [
                  for (var i = 0; i < denominator; i++)
                    Expanded(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: i < (numerator - k * denominator).clamp(0, denominator)
                              ? filledColor
                              : emptyColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.primary, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    } else {
      body = Wrap(
        alignment: WrapAlignment.center,
        spacing: Space.s,
        runSpacing: Space.s,
        children: [
          for (var i = 0; i < denominator; i++)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < numerator ? filledColor : Colors.transparent,
                border: Border.all(color: scheme.primary, width: 2.5),
              ),
              child: i < numerator
                  ? Icon(Icons.check, size: 20, color: scheme.onPrimary)
                  : null,
            ),
        ],
      );
    }

    return Semantics(
      label: '$numerator out of $denominator equal '
          '${style == FractionStyle.bar ? 'parts' : 'counters'} shaded, '
          'the fraction $numerator over $denominator.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            body,
            if (showLabel)
              Text('$numerator/$denominator', style: text.headlineMedium),
          ],
        ),
      ),
    );
  }
}
