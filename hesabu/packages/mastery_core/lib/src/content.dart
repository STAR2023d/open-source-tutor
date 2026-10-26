import 'models.dart';

/// All skills and questions for one or more grades, already parsed.
class ContentBundle {
  ContentBundle({required this.skills, required this.questions});

  final List<Skill> skills;
  final List<Question> questions;

  /// [skillsJson] is the decoded skills.json; [questionFiles] are the decoded
  /// questions_*.json files.
  factory ContentBundle.fromJson({
    required Map<String, dynamic> skillsJson,
    required List<Map<String, dynamic>> questionFiles,
  }) {
    final skills = (skillsJson['skills'] as List<dynamic>)
        .map((s) => Skill.fromJson(s as Map<String, dynamic>))
        .toList();
    final questions = <Question>[
      for (final file in questionFiles)
        for (final q in file['questions'] as List<dynamic>)
          Question.fromJson(q as Map<String, dynamic>),
    ];
    return ContentBundle(skills: skills, questions: questions);
  }

  List<Question> questionsFor(String skillId) =>
      questions.where((q) => q.skillId == skillId).toList();
}
