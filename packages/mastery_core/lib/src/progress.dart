import 'models.dart';

/// Indicative levels modelled on the four CBE/CBC performance levels
/// (EE, ME, AE, BE). This is NOT official KNEC grading.
enum PerformanceLevel {
  notStarted,
  belowExpectation,
  approachingExpectation,
  meetsExpectation,
  exceedsExpectation,
}

class Attempt {
  const Attempt({
    required this.questionId,
    required this.bloom,
    required this.correct,
    this.hintsUsed = 0,
    required this.at,
  });

  final String questionId;
  final BloomLevel bloom;
  final bool correct;
  final int hintsUsed;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'bloom': bloom.name,
        'correct': correct,
        'hintsUsed': hintsUsed,
        'at': at.toIso8601String(),
      };

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
        questionId: json['questionId'] as String,
        bloom: BloomLevel.values.byName(json['bloom'] as String),
        correct: json['correct'] as bool,
        hintsUsed: json['hintsUsed'] as int? ?? 0,
        at: DateTime.parse(json['at'] as String),
      );
}

/// Mastery rule (keep in sync with tools/validate_content.py):
/// over the last [window] attempts, accuracy >= [threshold], and at least
/// [minPerLevel] correct answers WITHOUT hints at every Bloom level from
/// Remember up to [masteryCeiling].
class SkillProgress {
  const SkillProgress({required this.skillId, this.attempts = const []});

  static const int window = 10;
  static const double threshold = 0.8;
  static const int minPerLevel = 2;
  static const BloomLevel masteryCeiling = BloomLevel.analyze;

  final String skillId;
  final List<Attempt> attempts;

  List<Attempt> get _recent => attempts.length <= window
      ? attempts
      : attempts.sublist(attempts.length - window);

  double get recentAccuracy {
    final r = _recent;
    if (r.isEmpty) return 0;
    return r.where((a) => a.correct).length / r.length;
  }

  int _cleanCorrectAt(BloomLevel level) => _recent
      .where((a) => a.bloom == level && a.correct && a.hintsUsed == 0)
      .length;

  /// The lowest Bloom level that still needs evidence.
  BloomLevel get nextTargetLevel {
    for (final level in BloomLevel.values) {
      if (level.index > masteryCeiling.index) break;
      if (_cleanCorrectAt(level) < minPerLevel) return level;
    }
    return masteryCeiling;
  }

  bool get isMastered {
    if (_recent.length < minPerLevel * (masteryCeiling.index + 1)) return false;
    if (recentAccuracy < threshold) return false;
    for (final level in BloomLevel.values) {
      if (level.index > masteryCeiling.index) break;
      if (_cleanCorrectAt(level) < minPerLevel) return false;
    }
    return true;
  }

  PerformanceLevel get performanceLevel {
    if (attempts.isEmpty) return PerformanceLevel.notStarted;
    if (isMastered) {
      final noHints = _recent.every((a) => a.hintsUsed == 0);
      return (recentAccuracy >= 0.9 && noHints)
          ? PerformanceLevel.exceedsExpectation
          : PerformanceLevel.meetsExpectation;
    }
    return recentAccuracy >= 0.5
        ? PerformanceLevel.approachingExpectation
        : PerformanceLevel.belowExpectation;
  }

  SkillProgress record(Attempt a) =>
      SkillProgress(skillId: skillId, attempts: [...attempts, a]);

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  factory SkillProgress.fromJson(Map<String, dynamic> json) => SkillProgress(
        skillId: json['skillId'] as String,
        attempts: (json['attempts'] as List<dynamic>)
            .map((a) => Attempt.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

/// A skill is unlocked when every prerequisite is mastered.
bool isUnlocked(Skill skill, Map<String, SkillProgress> progress) =>
    skill.prerequisites.every((id) => progress[id]?.isMastered ?? false);
