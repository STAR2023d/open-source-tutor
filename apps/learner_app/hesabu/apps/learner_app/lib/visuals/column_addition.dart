import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

/// Vertical (column) addition with optional regrouping digits.
///
/// Teaching use: making "carry the 1" visible. Carries are the small numbers
/// above the next column. Hide the result to let learners finish the sum.
class ColumnAddition extends StatelessWidget {
  const ColumnAddition({
    super.key,
    required this.a,
    required this.b,
    this.showCarries = false,
    this.showResult = false,
  }) : assert(a >= 0 && b >= 0);

  final int a;
  final int b;
  final bool showCarries;
  final bool showResult;

  static const double _cell = 44;

  @override
  Widget build(BuildContext context) {
    final sum = a + b;
    final cols = max(max(a.toString().length, b.toString().length), sum.toString().length);
    final aStr = a.toString().padLeft(cols);
    final bStr = b.toString().padLeft(cols);
    final sStr = sum.toString().padLeft(cols);

    // carryInto[i] = digit regrouped INTO column i from the column on its right.
    final carryInto = List<int>.filled(cols, 0);
    var carry = 0;
    for (var i = cols - 1; i >= 0; i--) {
      final da = aStr[i] == ' ' ? 0 : int.parse(aStr[i]);
      final db = bStr[i] == ' ' ? 0 : int.parse(bStr[i]);
      carry = (da + db + carry) ~/ 10;
      if (i > 0) carryInto[i - 1] = carry;
    }

    final scheme = Theme.of(context).colorScheme;
    final c = HesabuColors.of(context);
    final text = Theme.of(context).textTheme;
    // Fixed-width cells keep the digits aligned in columns.
    final digitStyle = text.headlineMedium;

    Widget cell(Widget child) => SizedBox(
          width: _cell,
          height: _cell + 4,
          child: Center(child: child),
        );

    Widget numberRow(String s, {String sign = ''}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(Text(sign, style: digitStyle)),
            for (var i = 0; i < cols; i++) cell(Text(s[i].trim(), style: digitStyle)),
          ],
        );

    final spoken = 'Column addition: $a plus $b'
        '${showResult ? ' equals $sum' : ''}.';

    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCarries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    cell(const SizedBox.shrink()),
                    for (var i = 0; i < cols; i++)
                      cell(carryInto[i] > 0
                          ? Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.tryAgainContainer,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.tryAgain, width: 1.5),
                              ),
                              child: Text('${carryInto[i]}',
                                  style: text.labelLarge
                                      ?.copyWith(color: c.onTryAgainContainer)),
                            )
                          : const SizedBox.shrink()),
                  ],
                ),
              numberRow(aStr),
              numberRow(bStr, sign: '+'),
              Container(
                width: _cell * (cols + 1),
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: Space.xs),
                color: scheme.onSurface,
              ),
              if (showResult)
                numberRow(sStr)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    cell(const SizedBox.shrink()),
                    for (var i = 0; i < cols; i++)
                      cell(Container(
                        width: _cell - 8,
                        height: _cell - 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.outline, width: 1.5),
                        ),
                      )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
