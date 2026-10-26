import 'package:flutter/material.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

enum FeedbackKind { correct, tryAgain, hint }

/// Announced to screen readers as soon as it appears (liveRegion).
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.kind,
    required this.title,
    this.lines = const [],
  });

  final FeedbackKind kind;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = HesabuColors.of(context);
    final (Color bg, Color fg, Color accent, IconData icon) = switch (kind) {
      FeedbackKind.correct => (c.successContainer, c.onSuccessContainer, c.success, Icons.check_circle),
      FeedbackKind.tryAgain => (c.tryAgainContainer, c.onTryAgainContainer, c.tryAgain, Icons.lightbulb),
      FeedbackKind.hint => (c.hintContainer, c.onHintContainer, c.hint, Icons.tips_and_updates_outlined),
    };
    final text = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: Radii.cardBr,
          border: Border.all(color: accent, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium?.copyWith(color: fg)),
                  for (final line in lines) ...[
                    const SizedBox(height: Space.xs),
                    Text(line, style: text.bodyLarge?.copyWith(color: fg)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
