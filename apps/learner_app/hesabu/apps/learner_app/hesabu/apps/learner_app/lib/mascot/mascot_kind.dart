import 'package:flutter/material.dart';

/// How the buddy feels. Used to react to the learner's answers.
enum MascotMood { happy, thinking, cheer, oops }

extension MascotMoodWord on MascotMood {
  String get word => switch (this) {
        MascotMood.happy => 'happy',
        MascotMood.thinking => 'thinking',
        MascotMood.cheer => 'cheerful',
        MascotMood.oops => 'encouraging',
      };
}

/// The three buddies a learner can pick. Names are Swahili animal names.
enum MascotKind { tembo, twiga, chui }

extension MascotKindInfo on MascotKind {
  String get displayName => switch (this) {
        MascotKind.tembo => 'Tembo',
        MascotKind.twiga => 'Twiga',
        MascotKind.chui => 'Chui',
      };

  String get animal => switch (this) {
        MascotKind.tembo => 'elephant',
        MascotKind.twiga => 'giraffe',
        MascotKind.chui => 'leopard',
      };

  String get tagline => switch (this) {
        MascotKind.tembo => 'Never forgets a number',
        MascotKind.twiga => 'Sees the big picture',
        MascotKind.chui => 'Quick and curious',
      };

  Color get color => switch (this) {
        MascotKind.tembo => const Color(0xFF8FA3B8),
        MascotKind.twiga => const Color(0xFFF6C85F),
        MascotKind.chui => const Color(0xFFE9A04B),
      };
}
