import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mastery_core/mastery_core.dart';

import '../data/profile_controller.dart';
import '../mascot/mascot.dart';
import '../theme/tokens.dart';
import '../widgets/bloom_ladder.dart';
import '../widgets/choice_tile.dart';
import '../widgets/feedback_card.dart';
import '../widgets/mastery_badge.dart';
import '../visuals/visual_factory.dart';
import '../widgets/soft_card.dart';
import '../widgets/visual_card.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.profile,
    required this.skill,
    required this.questions,
    required this.initial,
    required this.onProgress,
  });

  final ProfileController profile;
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
  final Random _rng = Random();
  final TextEditingController _controller = TextEditingController();

  Question? _current;
  // Display order of the choices. The JSON lists the correct answer first, so
  // we MUST shuffle or a child learns "the first one is always right".
  List<int> _order = const <int>[];
  AnswerResult? _result;
  int? _selected; // original index of the tapped choice
  int _hintsShown = 0;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    final q = _session.next();
    _current = q;
    _result = null;
    _selected = null;
    _hintsShown = 0;
    _controller.clear();
    _order = q == null
        ? const <int>[]
        : (List<int>.generate(q.choices.length, (i) => i)..shuffle(_rng));
  }

  void _submit(String response) {
    final q = _current!;
    final r = _session.submit(q, response, hintsUsed: _hintsShown);
    widget.onProgress(_session.progress);
    setState(() => _result = r);
  }

  void _pick(int originalIndex) {
    _selected = originalIndex;
    _submit('$originalIndex');
  }

  void _next() => setState(_advance);

  @override
  Widget build(BuildContext context) {
    final q = _current;
    return Scaffold(
      appBar: AppBar(title: Text(widget.skill.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: q == null ? _mastered(context) : _question(context, q),
          ),
        ),
      ),
    );
  }

  Widget _question(BuildContext context, Question q) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final answered = _result != null;
    final progress = _session.progress;

    return ListView(
      padding: const EdgeInsets.all(Space.m),
      children: [
        BloomLadder(progress: progress, target: progress.nextTargetLevel),
        const SizedBox(height: Space.l),
        SoftCard(
          color: scheme.surfaceContainerLowest,
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(q.bloom.icon, size: 18, color: scheme.primary),
                  const SizedBox(width: Space.xs + 2),
                  Text(q.bloom.kidLabel.toUpperCase(),
                      style: text.labelMedium?.copyWith(
                          color: scheme.primary, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: Space.s),
              Text(q.prompt, style: text.titleLarge),
            ],
          ),
        ),
        ..._visualBlock(q, answered),
        const SizedBox(height: Space.m),
        if (q.type == QuestionType.multipleChoice)
          ..._choices(q, answered)
        else
          ..._numeric(context, answered),
        const SizedBox(height: Space.m),
        for (var i = 0; i < _hintsShown; i++) ...[
          FeedbackCard(
            kind: FeedbackKind.hint,
            title: 'Hint ${i + 1}',
            lines: [q.hints[i]],
          ),
          const SizedBox(height: Space.s),
        ],
        if (!answered && _hintsShown < q.hints.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _hintsShown++),
              icon: const Icon(Icons.tips_and_updates_outlined),
              label: Text(_hintsShown == 0 ? 'I need a hint' : 'Another hint'),
            ),
          ),
        if (answered) ...[
          _feedback(q),
          const SizedBox(height: Space.m),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ),
        ],
        const SizedBox(height: Space.l),
      ],
    );
  }

  /// The teaching picture. Pictures marked `showWith: hint` appear when the
  /// learner asks for their first hint (which costs "clean" credit) or after
  /// answering, so they still help review.
  List<Widget> _visualBlock(Question q, bool answered) {
    final spec = q.visual;
    if (spec == null) return const [];
    final visible = spec.showWith == VisualReveal.prompt ||
        _hintsShown >= 1 ||
        answered;
    if (!visible) return const [];
    final visual = buildVisual(spec);
    if (visual == null) return const [];
    return [
      const SizedBox(height: Space.m),
      VisualCard(child: visual),
    ];
  }

  List<Widget> _choices(Question q, bool answered) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    return [
      for (var pos = 0; pos < _order.length; pos++)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s + 2),
          child: Builder(builder: (context) {
            final original = _order[pos];
            final choice = q.choices[original];
            final state = !answered
                ? ChoiceState.idle
                : choice.isCorrect
                    ? ChoiceState.correct
                    : original == _selected
                        ? ChoiceState.incorrect
                        : ChoiceState.dimmed;
            return ChoiceTile(
              label: letters[pos],
              text: choice.text,
              state: state,
              onTap: answered ? null : () => _pick(original),
            );
          }),
        ),
    ];
  }

  List<Widget> _numeric(BuildContext context, bool answered) {
    return [
      TextField(
        controller: _controller,
        enabled: !answered,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,. ]'))],
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: const InputDecoration(
          labelText: 'Type your answer',
        ),
        onSubmitted: answered ? null : _submit,
      ),
      const SizedBox(height: Space.m),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: answered ? null : () => _submit(_controller.text),
          child: const Text('Check my answer'),
        ),
      ),
    ];
  }

  Widget _feedback(Question q) {
    final r = _result!;
    final name = widget.profile.displayName;
    final phrases = r.correct
        ? ['Yes! Great thinking, $name!', 'Hongera, $name! (Well done!)', 'You nailed it!', 'Brilliant, $name!']
        : ['Not quite yet, $name. Let us look together.', 'Good try! Mistakes help us learn.', 'Almost! Read the explanation, then try the next one.'];
    return Column(
      children: [
        MascotBubble(
          kind: widget.profile.mascot,
          mood: r.correct ? MascotMood.cheer : MascotMood.oops,
          text: phrases[q.id.hashCode.abs() % phrases.length],
        ),
        const SizedBox(height: Space.s),
        _feedbackCard(q),
      ],
    );
  }

  Widget _feedbackCard(Question q) {
    final r = _result!;
    if (r.correct) {
      return FeedbackCard(
        kind: FeedbackKind.correct,
        title: 'Correct! Well done.',
        lines: [q.explanation],
      );
    }
    return FeedbackCard(
      kind: FeedbackKind.tryAgain,
      title: 'Not quite yet',
      lines: [
        if (r.feedback != null) r.feedback!,
        if (q.type == QuestionType.numericInput) 'The answer is ${q.answer}.',
        q.explanation,
      ],
    );
  }

  Widget _mastered(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final level = _session.progress.performanceLevel;
    return Padding(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0.5, end: 1),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Mascot(kind: widget.profile.mascot, mood: MascotMood.cheer, size: 150),
          ),
          const SizedBox(height: Space.m),
          Semantics(
            liveRegion: true,
            child: Text('Hongera, ${widget.profile.displayName}! Skill mastered!',
                style: text.headlineMedium, textAlign: TextAlign.center),
          ),
          const SizedBox(height: Space.s),
          Text(widget.skill.title, textAlign: TextAlign.center, style: text.bodyLarge),
          const SizedBox(height: Space.m),
          MasteryBadge(level: level),
          const SizedBox(height: Space.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Back to skills'),
            ),
          ),
        ],
      ),
    );
  }
}
