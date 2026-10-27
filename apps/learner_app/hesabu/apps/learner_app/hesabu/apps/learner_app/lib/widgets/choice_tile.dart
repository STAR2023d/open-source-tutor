import 'package:flutter/material.dart';

import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

enum ChoiceState { idle, correct, incorrect, dimmed }

/// One answer option: big tap target, letter badge, icon + colour for state.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String label; // 'A', 'B', ...
  final String text;
  final ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = HesabuColors.of(context);

    final (Color bg, Color border, Color fg, IconData? icon, String suffix) =
        switch (state) {
      ChoiceState.idle => (scheme.surfaceContainerLow, scheme.outline, scheme.onSurface, null, ''),
      ChoiceState.correct => (c.successContainer, c.success, c.onSuccessContainer, Icons.check_circle, ', correct answer'),
      ChoiceState.incorrect => (c.tryAgainContainer, c.tryAgain, c.onTryAgainContainer, Icons.close, ', not this one'),
      ChoiceState.dimmed => (scheme.surfaceContainerLow, scheme.outlineVariant, scheme.onSurfaceVariant, null, ''),
    };

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Option $label. $text$suffix',
      excludeSemantics: true,
      child: Material(
        color: bg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.controlBr,
          side: BorderSide(color: border, width: state == ChoiceState.idle ? 1.5 : 2.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s + 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: fg.withAlpha(30),
                    child: Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: fg)),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Text(text,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: fg)),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: Space.s),
                    Icon(icon, color: border),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
