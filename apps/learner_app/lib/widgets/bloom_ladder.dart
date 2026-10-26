import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

/// Child-friendly names and icons for Bloom's levels.
extension BloomUi on BloomLevel {
  String get kidLabel => switch (this) {
        BloomLevel.remember => 'Recall',
        BloomLevel.understand => 'Explain',
        BloomLevel.apply => 'Use it',
        BloomLevel.analyze => 'Think',
        BloomLevel.evaluate => 'Judge',
        BloomLevel.create => 'Create',
      };

  IconData get icon => switch (this) {
        BloomLevel.remember => Icons.bookmark_border,
        BloomLevel.understand => Icons.chat_bubble_outline,
        BloomLevel.apply => Icons.build_outlined,
        BloomLevel.analyze => Icons.travel_explore,
        BloomLevel.evaluate => Icons.balance,
        BloomLevel.create => Icons.auto_awesome,
      };
}

/// Shows the four mastery steps and how many clean answers each has.
class BloomLadder extends StatelessWidget {
  const BloomLadder({super.key, required this.progress, required this.target});

  final SkillProgress progress;
  final BloomLevel target;

  @override
  Widget build(BuildContext context) {
    final levels = BloomLevel.values
        .where((l) => l.index <= SkillProgress.masteryCeiling.index);
    return Row(
      children: [
        for (final level in levels)
          Expanded(
            child: _Step(
              level: level,
              clean: progress.cleanCorrectAt(level),
              isTarget: level == target,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.level, required this.clean, required this.isTarget});

  final BloomLevel level;
  final int clean;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = HesabuColors.of(context);
    const needed = SkillProgress.minPerLevel;
    final done = clean >= needed;

    final bg = done
        ? c.successContainer
        : isTarget
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh;
    final fg = done
        ? c.onSuccessContainer
        : isTarget
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant;

    return Semantics(
      label: '${level.kidLabel}: ${clean.clamp(0, needed)} of $needed done'
          '${isTarget ? ', current step' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isTarget && !done
                    ? Border.all(color: scheme.primary, width: 3)
                    : null,
              ),
              child: Icon(done ? Icons.check : level.icon, color: fg),
            ),
            const SizedBox(height: Space.xs),
            Text(level.kidLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: isTarget ? FontWeight.w700 : FontWeight.w500,
                    )),
            const SizedBox(height: Space.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < needed; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < clean ? Icons.circle : Icons.circle_outlined,
                      size: 10,
                      color: i < clean ? c.success : scheme.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
