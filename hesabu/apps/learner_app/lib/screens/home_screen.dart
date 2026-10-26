import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import '../data/storage.dart';
import '../theme/hesabu_colors.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import '../widgets/skill_card.dart';
import 'practice_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.content,
    required this.store,
    required this.theme,
  });

  final ContentBundle content;
  final ProgressStore store;
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, SkillProgress> _progress = widget.store.load();

  void _onProgress(SkillProgress p) {
    setState(() => _progress = {..._progress, p.skillId: p});
    widget.store.save(_progress);
  }

  Skill? _firstUnmasteredPrereq(Skill s) {
    for (final id in s.prerequisites) {
      if (!(_progress[id]?.isMastered ?? false)) {
        return widget.content.skills.firstWhere((x) => x.id == id);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.content.skills;
    final live = skills.where((s) => s.status == SkillStatus.live).toList();
    final mastered =
        live.where((s) => _progress[s.id]?.isMastered ?? false).length;

    final groups = <String, List<Skill>>{};
    for (final s in skills) {
      groups.putIfAbsent(s.subStrand, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabu'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(theme: widget.theme),
            )),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(Space.m),
            children: [
              _Summary(mastered: mastered, total: live.length),
              for (final entry in groups.entries) ...[
                _GroupHeader(
                  title: entry.key,
                  strand: entry.value.first.strand,
                ),
                for (final skill in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s + 2),
                    child: _card(skill),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Skill skill) {
    final progress = _progress[skill.id] ?? SkillProgress(skillId: skill.id);
    final live = skill.status == SkillStatus.live;
    final unlocked = live && isUnlocked(skill, _progress);
    final missing = _firstUnmasteredPrereq(skill);
    return SkillCard(
      skill: skill,
      progress: progress,
      unlocked: unlocked,
      lockedReason: missing == null ? null : 'Master "${missing.title}" first',
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          skill: skill,
          questions: widget.content.questionsFor(skill.id),
          initial: progress,
          onProgress: _onProgress,
        ),
      )),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.mastered, required this.total});

  final int mastered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final value = total == 0 ? 0.0 : mastered / total;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.m),
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: Radii.cardBr,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade 4 Maths',
              style: text.headlineMedium?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: Space.xs),
          Text(
            mastered == 0
                ? 'Pick a skill and start practising!'
                : '$mastered of $total skills mastered. Keep going!',
            style: text.bodyLarge?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: Space.m),
          Semantics(
            label: '$mastered of $total skills mastered',
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: scheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.strand});

  final String title;
  final String strand;

  @override
  Widget build(BuildContext context) {
    final colors = HesabuColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.m, bottom: Space.s),
      child: Row(
        children: [
          Icon(colors.strandIcon(strand), color: colors.strand(strand), size: 20),
          const SizedBox(width: Space.s),
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.strand(strand),
                    letterSpacing: 1,
                  )),
        ],
      ),
    );
  }
}
