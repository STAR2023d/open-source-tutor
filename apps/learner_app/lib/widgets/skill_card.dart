import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';
import 'mastery_badge.dart';
import 'soft_card.dart';

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    required this.progress,
    required this.unlocked,
    this.lockedReason,
    this.onTap,
  });

  final Skill skill;
  final SkillProgress progress;
  final bool unlocked;
  final String? lockedReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = HesabuColors.of(context);
    final text = Theme.of(context).textTheme;
    final live = skill.status == SkillStatus.live;
    final accent = colors.strand(skill.strand);

    final Widget status;
    if (!live) {
      status = Text('Coming soon',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    } else if (!unlocked) {
      status = Text(lockedReason ?? 'Locked',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    } else {
      status = MasteryBadge(level: progress.performanceLevel);
    }

    return Semantics(
      button: unlocked,
      child: SoftCard(
        onTap: unlocked ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color.alphaBlend(accent.withAlpha(40), scheme.surface),
                shape: BoxShape.circle,
              ),
              child: Icon(colors.strandIcon(skill.strand), color: accent),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skill.title, style: text.titleMedium),
                  const SizedBox(height: Space.xs + 2),
                  status,
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            Icon(
              !live
                  ? Icons.hourglass_empty
                  : unlocked
                      ? Icons.chevron_right
                      : Icons.lock_outline,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
