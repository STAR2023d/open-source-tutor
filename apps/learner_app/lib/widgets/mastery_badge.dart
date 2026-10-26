import 'package:flutter/material.dart';
import 'package:mastery_core/mastery_core.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

String levelLabel(PerformanceLevel l) => switch (l) {
      PerformanceLevel.notStarted => 'Not started',
      PerformanceLevel.belowExpectation => 'Keep practising',
      PerformanceLevel.approachingExpectation => 'Getting there',
      PerformanceLevel.meetsExpectation => 'Mastered',
      PerformanceLevel.exceedsExpectation => 'Mastered with distinction',
    };

/// Small pill showing indicative performance (not official KNEC grading).
class MasteryBadge extends StatelessWidget {
  const MasteryBadge({super.key, required this.level});

  final PerformanceLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = HesabuColors.of(context);

    final (Color bg, Color fg, IconData icon) = switch (level) {
      PerformanceLevel.notStarted => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant, Icons.radio_button_unchecked),
      PerformanceLevel.belowExpectation => (c.tryAgainContainer, c.onTryAgainContainer, Icons.fitness_center),
      PerformanceLevel.approachingExpectation => (c.hintContainer, c.onHintContainer, Icons.trending_up),
      PerformanceLevel.meetsExpectation => (c.successContainer, c.onSuccessContainer, Icons.check_circle),
      PerformanceLevel.exceedsExpectation => (c.successContainer, c.onSuccessContainer, Icons.workspace_premium),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s + 2, vertical: Space.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: Space.xs + 2),
          Flexible(
            child: Text(levelLabel(level),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
