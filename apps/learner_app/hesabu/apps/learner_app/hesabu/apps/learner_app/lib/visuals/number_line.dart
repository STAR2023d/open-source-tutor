import 'package:flutter/material.dart';

import 'format.dart';

class NumberLineMark {
  const NumberLineMark(this.value, {this.label});
  final double value;
  final String? label;
}

/// Number line with ticks and marked points.
///
/// Teaching use: ordering, rounding (where does 2,758 sit between 2,750 and
/// 2,760?), estimation, and later fractions and decimals.
class NumberLine extends StatelessWidget {
  const NumberLine({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    this.labelEvery = 1,
    this.marks = const [],
  })  : assert(max > min),
        assert(step > 0),
        assert(labelEvery >= 1);

  final double min;
  final double max;
  final double step;
  final int labelEvery;
  final List<NumberLineMark> marks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final markText = marks
        .map((m) => m.label ?? formatNumber(m.value))
        .join(' and ');
    return Semantics(
      label: 'Number line from ${formatNumber(min)} to ${formatNumber(max)}'
          '${marks.isEmpty ? '' : ', marked at $markText'}.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 128,
          width: double.infinity,
          child: CustomPaint(
            painter: _NumberLinePainter(
              min: min,
              max: max,
              step: step,
              labelEvery: labelEvery,
              marks: marks,
              lineColor: scheme.onSurface,
              markColor: scheme.primary,
              markTextColor: scheme.primary,
              tickTextStyle: (text.bodyMedium ?? const TextStyle())
                  .copyWith(color: scheme.onSurface, fontSize: 14),
              markTextStyle: (text.labelLarge ?? const TextStyle())
                  .copyWith(color: scheme.primary),
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.min,
    required this.max,
    required this.step,
    required this.labelEvery,
    required this.marks,
    required this.lineColor,
    required this.markColor,
    required this.markTextColor,
    required this.tickTextStyle,
    required this.markTextStyle,
    required this.textScaler,
  });

  final double min;
  final double max;
  final double step;
  final int labelEvery;
  final List<NumberLineMark> marks;
  final Color lineColor;
  final Color markColor;
  final Color markTextColor;
  final TextStyle tickTextStyle;
  final TextStyle markTextStyle;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 28.0;
    final y = size.height * 0.58;
    final w = size.width - 2 * pad;
    double x(double v) => pad + (v - min) / (max - min) * w;

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pad - 10, y), Offset(size.width - pad + 10, y), line);

    final n = ((max - min) / step).round();
    for (var i = 0; i <= n; i++) {
      final v = min + i * step;
      final major = i % labelEvery == 0;
      final h = major ? 12.0 : 7.0;
      canvas.drawLine(Offset(x(v), y - h), Offset(x(v), y + h), line..strokeWidth = major ? 3 : 2);
      if (major) {
        _text(canvas, size, formatNumber(v), Offset(x(v), y + h + 4), tickTextStyle);
      }
    }

    final fill = Paint()..color = markColor;
    for (final m in marks) {
      final cx = x(m.value.clamp(min, max).toDouble());
      canvas.drawLine(Offset(cx, y - 10), Offset(cx, y - 26), Paint()..color = markColor..strokeWidth = 3);
      canvas.drawCircle(Offset(cx, y), 9, fill);
      _text(canvas, size, m.label ?? formatNumber(m.value), Offset(cx, y - 28), markTextStyle,
          above: true);
    }
  }

  void _text(Canvas canvas, Size size, String s, Offset anchor, TextStyle style,
      {bool above = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final left = (anchor.dx - tp.width / 2)
        .clamp(0.0, max2(0.0, size.width - tp.width))
        .toDouble();
    final top = above ? anchor.dy - tp.height : anchor.dy;
    tp.paint(canvas, Offset(left, top));
  }

  static double max2(double a, double b) => a > b ? a : b;

  @override
  bool shouldRepaint(covariant _NumberLinePainter old) =>
      old.min != min ||
      old.max != max ||
      old.step != step ||
      old.labelEvery != labelEvery ||
      old.marks != marks ||
      old.lineColor != lineColor ||
      old.markColor != markColor ||
      old.textScaler != textScaler;
}
