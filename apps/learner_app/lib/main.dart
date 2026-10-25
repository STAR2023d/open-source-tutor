import 'dart:convert';

import 'package:content_pack/content_pack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mastery_core/mastery_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HesabuApp());

// ---------------------------------------------------------------- storage

/// Progress lives on the device only: no accounts, no personal data.
class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'progress.v1';

  Map<String, SkillProgress> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, SkillProgress.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> save(Map<String, SkillProgress> progress) => _prefs.setString(
        _key,
        jsonEncode(progress.map((k, v) => MapEntry(k, v.toJson()))),
      );
}

Future<ContentBundle> loadContent(String grade) async {
  Future<Map<String, dynamic>> read(String file) async => jsonDecode(
        await rootBundle.loadString('$contentRoot/$grade/$file'),
      ) as Map<String, dynamic>;

  final manifest = await read('manifest.json');
  final skills = await read(manifest['skills'] as String);
  final files = <Map<String, dynamic>>[
    for (final f in manifest['questions'] as List<dynamic>) await read(f as String),
  ];
  return ContentBundle.fromJson(skillsJson: skills, questionFiles: files);
}

String levelLabel(PerformanceLevel l) => switch (l) {
      PerformanceLevel.notStarted => 'Not started',
      PerformanceLevel.belowExpectation => 'Keep practising',
      PerformanceLevel.approachingExpectation => 'Getting there',
      PerformanceLevel.meetsExpectation => 'Mastered',
      PerformanceLevel.exceedsExpectation => 'Mastered with distinction',
    };

// -------------------------------------------------------------------- app

class HesabuApp extends StatelessWidget {
  const HesabuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hesabu',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const Bootstrap(),
      );
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late final Future<(ContentBundle, ProgressStore)> _future = _init();

  Future<(ContentBundle, ProgressStore)> _init() async {
    final content = await loadContent('grade4');
    final prefs = await SharedPreferences.getInstance();
    return (content, ProgressStore(prefs));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(body: Center(child: Text('Could not load: ${snap.error}')));
          }
          if (!snap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final (content, store) = snap.data!;
          return SkillListScreen(content: content, store: store);
        },
      );
}

class SkillListScreen extends StatefulWidget {
  const SkillListScreen({super.key, required this.content, required this.store});

  final ContentBundle content;
  final ProgressStore store;

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen> {
  late Map<String, SkillProgress> _progress = widget.store.load();

  void _onProgress(SkillProgress p) {
    setState(() => _progress = {..._progress, p.skillId: p});
    widget.store.save(_progress);
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.content.skills;
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabu - Grade 4 Maths')),
      body: ListView.builder(
        itemCount: skills.length,
        itemBuilder: (context, i) {
          final skill = skills[i];
          final progress = _progress[skill.id] ?? SkillProgress(skillId: skill.id);
          final live = skill.status == SkillStatus.live;
          final unlocked = live && isUnlocked(skill, _progress);
          return ListTile(
            enabled: unlocked,
            leading: Icon(!live
                ? Icons.hourglass_empty
                : unlocked
                    ? (progress.isMastered ? Icons.check_circle : Icons.play_circle)
                    : Icons.lock),
            title: Text(skill.title),
            subtitle: Text(!live
                ? 'Coming soon'
                : unlocked
                    ? levelLabel(progress.performanceLevel)
                    : 'Master the earlier skills first'),
            onTap: unlocked
                ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => PracticeScreen(
                        skill: skill,
                        questions: widget.content.questionsFor(skill.id),
                        initial: progress,
                        onProgress: _onProgress,
                      ),
                    ))
                : null,
          );
        },
      ),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.skill,
    required this.questions,
    required this.initial,
    required this.onProgress,
  });

  final Skill skill;
  final List<Question> questions;
  final SkillProgress initial;
  final ValueChanged<SkillProgress> onProgress;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeSession _session = PracticeSession(
    skill: widget.skill,
    questions: widget.questions,
    progress: widget.initial,
  );
  late Question? _current = _session.next();
  AnswerResult? _result;
  int _hintsShown = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String response) {
    final q = _current!;
    final r = _session.submit(q, response, hintsUsed: _hintsShown);
    widget.onProgress(_session.progress);
    setState(() => _result = r);
  }

  void _next() => setState(() {
        _result = null;
        _hintsShown = 0;
        _controller.clear();
        _current = _session.next();
      });

  @override
  Widget build(BuildContext context) {
    final q = _current;
    return Scaffold(
      appBar: AppBar(title: Text(widget.skill.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: q == null ? _mastered(context) : _question(context, q),
      ),
    );
  }

  Widget _mastered(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
            const SizedBox(height: 12),
            Text('Skill mastered!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(levelLabel(_session.progress.performanceLevel)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to skills'),
            ),
          ],
        ),
      );

  Widget _question(BuildContext context, Question q) {
    final answered = _result != null;
    return ListView(
      children: [
        Text(q.bloom.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (q.type == QuestionType.multipleChoice)
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: answered ? null : () => _submit('$i'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(q.choices[i].text),
                ),
              ),
            )
        else ...[
          TextField(
            controller: _controller,
            enabled: !answered,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Your answer',
            ),
            onSubmitted: answered ? null : _submit,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: answered ? null : () => _submit(_controller.text),
            child: const Text('Check'),
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < _hintsShown; i++) Text('Hint ${i + 1}: ${q.hints[i]}'),
        if (!answered && _hintsShown < q.hints.length)
          TextButton(
            onPressed: () => setState(() => _hintsShown++),
            child: const Text('I need a hint'),
          ),
        if (answered) ...[
          const Divider(),
          Text(
            _result!.correct ? 'Correct!' : 'Not quite.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!_result!.correct && _result!.feedback != null) Text(_result!.feedback!),
          const SizedBox(height: 8),
          Text(q.explanation),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: const Text('Next')),
        ],
      ],
    );
  }
}
