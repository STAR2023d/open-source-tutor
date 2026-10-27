import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rows x columns array of unit squares.
///
/// Teaching use: multiplication as equal groups and area of rectangles as
/// "rows multiplied by columns" (the Grade 4 area outcome).
class ArrayGrid extends StatelessWidget {
  const ArrayGrid({
    super.key,
    required this.rows,
    required this.cols,
    this.showCounts = true,
  })  : assert(rows >= 1 && rows <= 12),
        assert(cols >= 1 && cols <= 12);

  final int rows;
  final int cols;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'A grid of unit squares with $rows rows and $cols columns.',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCounts) Text('$cols columns', style: text.labelLarge),
              const SizedBox(height: Space.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showCounts)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.s),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text('$rows rows', style: text.labelLarge),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < rows; r++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var c = 0; c < cols; c++)
                              Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: scheme.primary, width: 1.5),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
