import 'dart:math';

import 'models.dart';
import 'progress.dart';

/// Chooses the next question for one skill and records attempts.
class PracticeSession {
  PracticeSession({
    required this.skill,
    required this.questions,
    required SkillProgress progress,
    Random? random,
  })  : _progress = progress,
        _random = random ?? Random();

  final Skill skill;
  final List<Question> questions;
  final Random _random;
  SkillProgress _progress;

  SkillProgress get progress => _progress;

  /// Returns null when the skill is mastered or there are no questions.
  Question? next() {
    if (_progress.isMastered || questions.isEmpty) return null;
    final target = _progress.nextTargetLevel;
    final recentIds =
        _progress.attempts.reversed.take(4).map((a) => a.questionId).toSet();

    var pool = questions
        .where((q) => q.bloom == target && !recentIds.contains(q.id))
        .toList();
    if (pool.isEmpty) pool = questions.where((q) => q.bloom == target).toList();
    if (pool.isEmpty) {
      pool = questions.where((q) => !recentIds.contains(q.id)).toList();
    }
    if (pool.isEmpty) pool = List.of(questions);
    return pool[_random.nextInt(pool.length)];
  }

  AnswerResult submit(Question q, String response, {int hintsUsed = 0}) {
    final result = q.check(response);
    _progress = _progress.record(Attempt(
      questionId: q.id,
      bloom: q.bloom,
      correct: result.correct,
      hintsUsed: hintsUsed,
      at: DateTime.now(),
    ));
    return result;
  }
}
