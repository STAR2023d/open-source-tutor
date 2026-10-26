import 'package:flutter/material.dart';

/// Spacing scale (logical pixels). Use these instead of magic numbers.
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

abstract final class Radii {
  static const double card = 20;
  static const double control = 16;
  static BorderRadius get cardBr => BorderRadius.circular(card);
  static BorderRadius get controlBr => BorderRadius.circular(control);
}

/// Readable line length on web and tablets.
const double kMaxContentWidth = 720;

/// Minimum size for anything a child taps (Material says 48; small hands need more).
const double kMinTapTarget = 56;
