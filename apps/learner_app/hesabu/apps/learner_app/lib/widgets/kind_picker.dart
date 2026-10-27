import 'package:flutter/material.dart';

import '../mascot/mascot.dart';
import '../theme/tokens.dart';

/// Three selectable buddy cards. Shared by onboarding and Settings.
class KindPicker extends StatelessWidget {
  const KindPicker({super.key, required this.selected, required this.onChanged});

  final MascotKind selected;
  final ValueChanged<MascotKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in MascotKind.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _KindCard(
                  kind: kind,
                  isSelected: kind == selected,
                  onTap: () => onChanged(kind),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.isSelected,
    required this.onTap,
  });

  final MascotKind kind;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${kind.displayName}, the ${kind.animal}. ${kind.tagline}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardBr,
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.s),
            child: Column(
              children: [
                Mascot(
                  kind: kind,
                  mood: isSelected ? MascotMood.cheer : MascotMood.happy,
                  size: 72,
                ),
                const SizedBox(height: Space.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.check_circle, size: 18, color: scheme.primary),
                      ),
                    Flexible(
                      child: Text(kind.displayName,
                          style: text.titleMedium, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  kind.tagline,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
