import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'mascot_kind.dart';

export 'mascot_kind.dart';

/// A buddy drawn entirely in code: offline, tiny, and free of art licences.
/// All coordinates are in a 100 x 100 box that is scaled to the widget size.
class MascotPainter extends CustomPainter {
  const MascotPainter({required this.kind, required this.mood, this.bounce = 0});

  final MascotKind kind;
  final MascotMood mood;

  /// 0..1 hop height, driven by [BouncyMascot].
  final double bounce;

  static const _ink = Color(0xFF2B2B2B);
  static const _pink = Color(0xFFF4B6C2);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // ground shadow stays on the floor while the buddy hops
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 97), width: 44 - bounce * 6, height: 6),
      Paint()..color = const Color(0x26000000),
    );
    canvas.translate(0, -bounce * 3);

    final base = kind.color;
    final line = Color.lerp(base, const Color(0xFF000000), 0.45)!;

    _behind(canvas, base, line);
    _arms(canvas, base, line);
    _oval(canvas, const Offset(50, 80), 54, 36, base, line); // body
    _oval(canvas, const Offset(36, 95), 16, 8, base, line); // feet
    _oval(canvas, const Offset(64, 95), 16, 8, base, line);
    _circle(canvas, const Offset(50, 44), 30, base, line); // head
    _front(canvas, base, line);
    _face(canvas);
    _extras(canvas);

    canvas.restore();
  }

  // ---------------------------------------------------------------- parts

  void _behind(Canvas c, Color base, Color line) {
    switch (kind) {
      case MascotKind.tembo:
        for (final x in [20.0, 80.0]) {
          _circle(c, Offset(x, 44), 17, base, line);
          _circle(c, Offset(x, 44), 10, _pink, line, sw: 0);
        }
      case MascotKind.twiga:
        for (final s in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + s * 30, 32);
          c.rotate(s * 0.5);
          _oval(c, Offset.zero, 18, 11, base, line);
          c.restore();
          // ossicones (the little horns)
          final top = Offset(50 + s * 9, 7);
          _stroke(c, Path()..moveTo(50 + s * 11, 18)..lineTo(top.dx, top.dy), line, 4);
          c.drawCircle(top, 4, Paint()..color = line);
        }
      case MascotKind.chui:
        for (final x in [27.0, 73.0]) {
          _circle(c, Offset(x, 21), 10, base, line);
          _circle(c, Offset(x, 22), 5, _pink, line, sw: 0);
        }
        // tail
        final tail = Path()
          ..moveTo(76, 84)
          ..quadraticBezierTo(97, 86, 91, 66);
        _stroke(c, tail, line, 9);
        _stroke(c, tail, base, 6);
    }
  }

  void _arms(Canvas c, Color base, Color line) {
    void limb(Offset a, Offset b) {
      final p = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy);
      _stroke(c, p, line, 11);
      _stroke(c, p, base, 8);
    }

    switch (mood) {
      case MascotMood.cheer:
        limb(const Offset(28, 72), const Offset(15, 52));
        limb(const Offset(72, 72), const Offset(85, 52));
      case MascotMood.thinking:
        limb(const Offset(28, 74), const Offset(22, 89));
        limb(const Offset(72, 74), const Offset(63, 66));
      case MascotMood.happy:
      case MascotMood.oops:
        limb(const Offset(28, 74), const Offset(22, 89));
        limb(const Offset(72, 74), const Offset(78, 89));
    }
  }

  void _front(Canvas c, Color base, Color line) {
    switch (kind) {
      case MascotKind.tembo:
        final trunk = Path()
          ..moveTo(50, 56)
          ..quadraticBezierTo(50, 84, 63, 82);
        _stroke(c, trunk, line, 15);
        _stroke(c, trunk, base, 12);
      case MascotKind.twiga:
        const spot = Color(0xFFB5651D);
        for (final s in const [
          [32.0, 28.0, 5.0],
          [68.0, 27.0, 4.0],
          [74.0, 42.0, 3.5],
          [38.0, 76.0, 5.0],
          [62.0, 82.0, 5.0],
          [50.0, 89.0, 3.5],
        ]) {
          c.drawCircle(Offset(s[0], s[1]), s[2], Paint()..color = spot);
        }
        _oval(c, const Offset(50, 59), 32, 22, const Color(0xFFFBE3B0), line);
        for (final x in [45.0, 55.0]) {
          c.drawCircle(Offset(x, 59), 1.7, Paint()..color = line);
        }
      case MascotKind.chui:
        const spot = Color(0xFF5A3A12);
        for (final s in const [
          [30.0, 36.0, 3.5],
          [70.0, 34.0, 3.5],
          [37.0, 27.0, 3.0],
          [63.0, 25.0, 3.0],
          [24.0, 50.0, 3.0],
          [38.0, 76.0, 4.5],
          [62.0, 82.0, 4.5],
          [50.0, 89.0, 3.0],
        ]) {
          c.drawCircle(Offset(s[0], s[1]), s[2], Paint()..color = spot);
        }
        _oval(c, const Offset(50, 58), 30, 20, const Color(0xFFFCE9C4), line);
        c.drawCircle(const Offset(50, 53), 3.2, Paint()..color = const Color(0xFFB5535F));
    }
  }

  void _face(Canvas c) {
    final eyeY = kind == MascotKind.tembo ? 40.0 : 42.0;
    final look = switch (mood) {
      MascotMood.thinking => const Offset(1.8, -2.2),
      MascotMood.oops => const Offset(0, 1.6),
      _ => const Offset(0, 0.4),
    };
    for (final x in [40.0, 60.0]) {
      c.drawCircle(Offset(x, eyeY), 7, Paint()..color = _white);
      c.drawCircle(Offset(x, eyeY), 7,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = _ink);
      c.drawCircle(Offset(x, eyeY) + look, mood == MascotMood.oops ? 3 : 3.6,
          Paint()..color = _ink);
      c.drawCircle(Offset(x, eyeY) + look + const Offset(1.2, -1.2), 1.1,
          Paint()..color = _white);
    }

    // eyebrows
    final by = eyeY - 11;
    switch (mood) {
      case MascotMood.happy:
        break;
      case MascotMood.cheer:
        _stroke(c, Path()..moveTo(35, by + 1)..quadraticBezierTo(40, by - 3, 45, by + 1), _ink, 2.2);
        _stroke(c, Path()..moveTo(55, by + 1)..quadraticBezierTo(60, by - 3, 65, by + 1), _ink, 2.2);
      case MascotMood.thinking:
        _stroke(c, Path()..moveTo(35, by + 2)..lineTo(45, by + 2), _ink, 2.2);
        _stroke(c, Path()..moveTo(55, by)..lineTo(65, by - 3), _ink, 2.2);
      case MascotMood.oops:
        _stroke(c, Path()..moveTo(35, by + 3)..lineTo(45, by), _ink, 2.2);
        _stroke(c, Path()..moveTo(55, by)..lineTo(65, by + 3), _ink, 2.2);
    }

    // cheeks
    for (final x in [31.0, 69.0]) {
      c.drawCircle(Offset(x, 54), 5, Paint()..color = const Color(0x59FF8FA3));
    }

    // mouth (the elephant's trunk sits in the middle, so it smiles on both sides)
    if (kind == MascotKind.tembo) {
      _mouth(c, 37, 64, 8, small: true);
      _mouth(c, 63, 64, 8, small: true);
    } else {
      _mouth(c, 50, kind == MascotKind.twiga ? 66.5 : 65, 16);
    }
  }

  void _mouth(Canvas c, double cx, double my, double w, {bool small = false}) {
    final l = cx - w / 2;
    final r = cx + w / 2;
    switch (mood) {
      case MascotMood.happy:
        _stroke(c, Path()..moveTo(l, my)..quadraticBezierTo(cx, my + 8, r, my), _ink, 2.4);
      case MascotMood.cheer when small:
        // a wide open mouth would collide with the trunk, so grin instead
        _stroke(c, Path()..moveTo(l, my)..quadraticBezierTo(cx, my + 12, r, my), _ink, 2.8);
      case MascotMood.cheer:
        final open = Path()
          ..moveTo(l, my - 1)
          ..quadraticBezierTo(cx, my + 15, r, my - 1)
          ..close();
        c.drawPath(open, Paint()..color = const Color(0xFF7A2E3A));
      case MascotMood.thinking:
        _stroke(c, Path()..moveTo(cx - w / 4, my + 2)..lineTo(cx + w / 4, my), _ink, 2.4);
      case MascotMood.oops:
        _stroke(c, Path()..moveTo(l + 2, my + 3)..quadraticBezierTo(cx, my - 3, r - 2, my + 3), _ink, 2.4);
    }
  }

  void _extras(Canvas c) {
    switch (mood) {
      case MascotMood.cheer:
        const gold = Color(0xFFFFC107);
        for (final s in const [
          [10.0, 20.0, 6.0],
          [90.0, 16.0, 7.0],
          [93.0, 44.0, 5.0],
          [8.0, 46.0, 4.5],
        ]) {
          c.drawPath(_sparkle(Offset(s[0], s[1]), s[2]), Paint()..color = gold);
        }
      case MascotMood.thinking:
        final dot = Paint()..color = const Color(0xFF9AA5B1);
        c.drawCircle(const Offset(78, 14), 2, dot);
        c.drawCircle(const Offset(84, 8), 3, dot);
        c.drawCircle(const Offset(91, 3), 4, dot);
      case MascotMood.oops:
        final drop = Path()
          ..moveTo(80, 22)
          ..quadraticBezierTo(73, 31, 80, 35)
          ..quadraticBezierTo(87, 31, 80, 22);
        c.drawPath(drop, Paint()..color = const Color(0xFF7EC8F2));
      case MascotMood.happy:
        break;
    }
  }

  // -------------------------------------------------------------- helpers

  Path _sparkle(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.35;
      final pt = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  void _oval(Canvas c, Offset center, double w, double h, Color fill, Color line,
      {double sw = 2}) {
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    c.drawOval(rect, Paint()..color = fill);
    if (sw > 0) {
      c.drawOval(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = line);
    }
  }

  void _circle(Canvas c, Offset center, double r, Color fill, Color line,
      {double sw = 2}) =>
      _oval(c, center, r * 2, r * 2, fill, line, sw: sw);

  void _stroke(Canvas c, Path p, Color color, double width) {
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant MascotPainter old) =>
      old.kind != kind || old.mood != mood || old.bounce != bounce;
}

/// A still buddy.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.kind,
    this.mood = MascotMood.happy,
    this.size = 96,
    this.bounce = 0,
  });

  final MascotKind kind;
  final MascotMood mood;
  final double size;
  final double bounce;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: '${kind.displayName} the ${kind.animal}, looking ${mood.word}',
        child: ExcludeSemantics(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: MascotPainter(kind: kind, mood: mood, bounce: bounce),
            ),
          ),
        ),
      );
}

/// A buddy that gently hops. Stays still when the device asks for reduced motion.
class BouncyMascot extends StatefulWidget {
  const BouncyMascot({
    super.key,
    required this.kind,
    this.mood = MascotMood.happy,
    this.size = 160,
  });

  final MascotKind kind;
  final MascotMood mood;
  final double size;

  @override
  State<BouncyMascot> createState() => _BouncyMascotState();
}

class _BouncyMascotState extends State<BouncyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Mascot(
          kind: widget.kind,
          mood: widget.mood,
          size: widget.size,
          bounce: Curves.easeInOut.transform(_controller.value),
        ),
      );
}

/// Buddy plus a speech bubble. Used for encouragement after answers.
class MascotBubble extends StatelessWidget {
  const MascotBubble({
    super.key,
    required this.kind,
    required this.mood,
    required this.text,
  });

  final MascotKind kind;
  final MascotMood mood;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(kind: kind, mood: mood, size: 64),
        const SizedBox(width: Space.s),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.m, vertical: Space.s + 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(Radii.card),
                  bottomLeft: Radius.circular(Radii.card),
                  bottomRight: Radius.circular(Radii.card),
                ),
              ),
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ),
      ],
    );
  }
}
