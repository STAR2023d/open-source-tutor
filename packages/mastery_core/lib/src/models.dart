/// Revised Bloom's taxonomy (Anderson & Krathwohl, 2001).
enum BloomLevel { remember, understand, apply, analyze, evaluate, create }

enum QuestionType { multipleChoice, numericInput }

enum SkillStatus { planned, live }

class Skill {
  const Skill({
    required this.id,
    required this.title,
    required this.grade,
    required this.strand,
    required this.subStrand,
    this.prerequisites = const [],
    this.status = SkillStatus.planned,
    this.kicdRef,
  });

  final String id;
  final String title;
  final int grade;
  final String strand;
  final String subStrand;
  final List<String> prerequisites;
  final SkillStatus status;

  /// Short pointer to the curriculum design (we reference, we do not copy).
  final String? kicdRef;

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        title: json['title'] as String,
        grade: json['grade'] as int,
        strand: json['strand'] as String,
        subStrand: json['subStrand'] as String,
        prerequisites:
            ((json['prerequisites'] as List<dynamic>?) ?? const []).cast<String>(),
        status: SkillStatus.values.byName(json['status'] as String? ?? 'planned'),
        kicdRef: json['kicdRef'] as String?,
      );
}

class Choice {
  const Choice({
    required this.text,
    this.isCorrect = false,
    this.misconception,
    this.feedback,
  });

  final String text;
  final bool isCorrect;
  final String? misconception;
  final String? feedback;

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
        text: json['text'] as String,
        isCorrect: json['correct'] as bool? ?? false,
        misconception: json['misconception'] as String?,
        feedback: json['feedback'] as String?,
      );
}

class AnswerResult {
  const AnswerResult({required this.correct, this.feedback, this.misconception});

  final bool correct;
  final String? feedback;
  final String? misconception;
}

class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.bloom,
    required this.type,
    required this.prompt,
    this.choices = const [],
    this.answer,
    this.hints = const [],
    required this.explanation,
  });

  final String id;
  final String skillId;
  final BloomLevel bloom;
  final QuestionType type;
  final String prompt;
  final List<Choice> choices;
  final String? answer;
  final List<String> hints;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        skillId: json['skillId'] as String,
        bloom: BloomLevel.values.byName(json['bloom'] as String),
        type: QuestionType.values.byName(json['type'] as String),
        prompt: json['prompt'] as String,
        choices: ((json['choices'] as List<dynamic>?) ?? const [])
            .map((c) => Choice.fromJson(c as Map<String, dynamic>))
            .toList(),
        answer: json['answer'] as String?,
        hints: ((json['hints'] as List<dynamic>?) ?? const []).cast<String>(),
        explanation: json['explanation'] as String,
      );

  /// Checks a response. For multiple choice, [response] is the index of the
  /// chosen option in [choices]. For numeric input it is what the child typed.
  AnswerResult check(String response) {
    switch (type) {
      case QuestionType.multipleChoice:
        final index = int.tryParse(response);
        if (index == null || index < 0 || index >= choices.length) {
          return const AnswerResult(correct: false);
        }
        final c = choices[index];
        return AnswerResult(
          correct: c.isCorrect,
          feedback: c.feedback,
          misconception: c.misconception,
        );
      case QuestionType.numericInput:
        final typed = num.tryParse(response.replaceAll(RegExp(r'[,\s]'), ''));
        final expected = num.tryParse(answer ?? '');
        return AnswerResult(
          correct: typed != null && expected != null && typed == expected,
        );
    }
  }
}
