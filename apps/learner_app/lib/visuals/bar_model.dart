import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class BarPart {
  const BarPart({required this.label, required this.value});
  final String label;
  final String value;
}

/// Part-whole bar model ("Singapore bar"): parts sit under one total bar.
///
/// Teaching use: turning a word problem into a picture before choosing an
/// operation. Use "?" for the unknown part or total.
class BarModel extends StatelessWidget {
  const BarModel({
    super.key,
    required this.parts,
    this.total = '?',
    this.totalLabel = 'Total',
  });

  final List<BarPart> parts;
  final String total;
  final String totalLabel;

  int _flexFor(BarPart p, double sum) {
    final n = double.tryParse(p.value.replaceAll(',', ''));
    if (n == null || sum <= 0) return 1000 ~/ parts.length;
    return (n / sum * 1000).round().clamp(120, 1000).toInt();
  }

  @override
  Widget build(BuildContext context) {
    // Not an initializer assert: List.length is not allowed in a const constructor.
    assert(parts.length >= 2, 'A bar model needs at least two parts');
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sum = parts
        .map((p) => double.tryParse(p.value.replaceAll(',', '')) ?? 0)
        .fold<double>(0, (a, b) => a + b);

    final spoken = 'Bar model. ${parts.map((p) => '${p.label} ${p.value}').join(' and ')}'
        ' make a $totalLabel of $total.';

    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(Radii.control - 4),
              ),
              child: Text('$totalLabel: $total',
                  style: text.titleMedium?.copyWith(color: scheme.onTertiaryContainer)),
            ),
            // bracket joining the total to its parts
            Container(
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: scheme.outline, width: 2),
                  right: BorderSide(color: scheme.outline, width: 2),
                  bottom: BorderSide(color: scheme.outline, width: 2),
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    flex: _flexFor(parts[i], sum),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Space.s + 2, horizontal: Space.xs),
                      decoration: BoxDecoration(
                        color: i.isEven ? scheme.primaryContainer : scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(Radii.control - 4),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(parts[i].label,
                                style: text.labelMedium?.copyWith(
                                    color: i.isEven
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSecondaryContainer)),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(parts[i].value,
                                style: text.titleMedium?.copyWith(
                                    color: i.isEven
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSecondaryContainer)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
