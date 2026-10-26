import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'soft_card.dart';

/// Frames a teaching picture with a friendly heading.
class VisualCard extends StatelessWidget {
  const VisualCard({super.key, required this.child, this.title = 'Picture it'});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      color: scheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: Space.xs + 2),
              Text(title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: Space.m),
          Center(child: child),
        ],
      ),
    );
  }
}
