import 'dart:math';

import 'package:mastery_core/mastery_core.dart';
import 'package:test/test.dart';

Attempt attempt(BloomLevel b, {bool correct = true, int hints = 0}) => Attempt(
      questionId: 'q-${b.name}',
      bloom: b,
      correct: correct,
      hintsUsed: hints,
      at: DateTime(2026, 1, 1),
    );

const coreLevels = [
  BloomLevel.remember,
  BloomLevel.understand,
  BloomLevel.apply,
  BloomLevel.analyze,
];

void main() {
  group('SkillProgress', () {
    test('starts not started and not mastered', () {
      const p = SkillProgress(skillId: 's');
      expect(p.isMastered, isFalse);
      expect(p.performanceLevel, PerformanceLevel.notStarted);
      expect(p.nextTargetLevel, BloomLevel.remember);
    });

    test('mastered after two clean correct answers at each core level', () {
      var p = const SkillProgress(skillId: 's');
      for (final b in coreLevels) {
        p = p.record(attempt(b)).record(attempt(b));
      }
      expect(p.isMastered, isTrue);
      expect(p.performanceLevel, PerformanceLevel.exceedsExpectation);
    });

    test('answers that used hints do not count towards mastery', () {
      var p = const SkillProgress(skillId: 's');
      for (final b in coreLevels) {
        p = p.record(attempt(b)).record(attempt(b, hints: 1));
      }
      expect(p.isMastered, isFalse);
      expect(p.nextTargetLevel, BloomLevel.remember);
    });

    test('target level moves up as evidence accumulates', () {
      var p = const SkillProgress(skillId: 's');
      p = p.record(attempt(BloomLevel.remember)).record(attempt(BloomLevel.remember));
      expect(p.nextTargetLevel, BloomLevel.understand);
    });

    test('json round trip keeps attempts', () {
      final p = const SkillProgress(skillId: 's').record(attempt(BloomLevel.apply));
      final copy = SkillProgress.fromJson(p.toJson());
      expect(copy.attempts.single.bloom, BloomLevel.apply);
    });
  });

  group('Question.check', () {
    const numeric = Question(
      id: 'n1',
      skillId: 's',
      bloom: BloomLevel.apply,
      type: QuestionType.numericInput,
      prompt: '?',
      answer: '46052',
      explanation: 'e',
    );

    test('accepts commas and spaces in numeric answers', () {
      expect(numeric.check('46,052').correct, isTrue);
      expect(numeric.check(' 46052 ').correct, isTrue);
      expect(numeric.check('46053').correct, isFalse);
      expect(numeric.check('abc').correct, isFalse);
    });

    test('multiple choice returns misconception tag', () {
      const mc = Question(
        id: 'm1',
        skillId: 's',
        bloom: BloomLevel.remember,
        type: QuestionType.multipleChoice,
        prompt: '?',
        choices: [
          Choice(text: 'right', isCorrect: true),
          Choice(text: 'wrong', misconception: 'off_by_one_place'),
        ],
        explanation: 'e',
      );
      expect(mc.check('0').correct, isTrue);
      expect(mc.check('1').misconception, 'off_by_one_place');
      expect(mc.check('9').correct, isFalse);
    });
  });

  group('PracticeSession', () {
    test('serves a Remember question first and stops when mastered', () {
      const skill = Skill(id: 's', title: 't', grade: 4, strand: 'N', subStrand: 'W');
      final questions = [
        for (final b in coreLevels)
          for (var i = 0; i < 2; i++)
            Question(
              id: '${b.name}$i',
              skillId: 's',
              bloom: b,
              type: QuestionType.numericInput,
              prompt: '?',
              answer: '1',
              explanation: 'e',
            ),
      ];
      final session = PracticeSession(
        skill: skill,
        questions: questions,
        progress: const SkillProgress(skillId: 's'),
        random: Random(1),
      );
      expect(session.next()!.bloom, BloomLevel.remember);

      for (var i = 0; i < 20 && session.next() != null; i++) {
        session.submit(session.next()!, '1');
      }
      expect(session.progress.isMastered, isTrue);
      expect(session.next(), isNull);
    });
  });

  group('VisualSpec', () {
    test('parses type, reveal timing and params', () {
      final q = Question.fromJson({
        'id': 'q',
        'skillId': 's',
        'bloom': 'apply',
        'type': 'numericInput',
        'prompt': '?',
        'answer': '1',
        'explanation': 'e',
        'visual': {
          'type': 'placeValueChart',
          'value': 5382,
          'showWith': 'hint',
          'highlight': ['hundreds'],
        },
      });
      expect(q.visual!.type, 'placeValueChart');
      expect(q.visual!.showWith, VisualReveal.hint);
      expect(q.visual!.params['value'], 5382);
      expect(q.visual!.params.containsKey('type'), isFalse);
    });

    test('question without a visual has none', () {
      final q = Question.fromJson({
        'id': 'q',
        'skillId': 's',
        'bloom': 'apply',
        'type': 'numericInput',
        'prompt': '?',
        'answer': '1',
        'explanation': 'e',
      });
      expect(q.visual, isNull);
    });
  });
}
