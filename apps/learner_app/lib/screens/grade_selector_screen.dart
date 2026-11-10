import 'package:flutter/material.dart';

import '../data/profile_controller.dart';
import '../theme/hesabu_colors.dart';
import '../theme/tokens.dart';

/// A screen that lets the learner pick which grade to practise.
///
/// Grades are shown with: number badge, title, strand icon, subtitle, and
/// a status label (e.g. "Completed", "New", "Coming soon"). Tapping a grade
/// calls [onGradeSelected] and returns to the previous screen.
class GradeSelectorScreen extends StatefulWidget {
  const GradeSelectorScreen({
    super.key,
    required this.profile,
    this.initialGrade,
    required this.onGradeSelected,
  });

  final ProfileController profile;
  final String? initialGrade;
  final ValueChanged<String> onGradeSelected;

  @override
  State<GradeSelectorScreen> createState() => _GradeSelectorScreenState();
}

class _GradeSelectorScreenState extends State<GradeSelectorScreen> {
  late String _selectedGrade;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade ?? widget.profile.grade;
  }

  void _pickGrade(String grade) {
    widget.onGradeSelected(grade);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = HesabuColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your grade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          const SizedBox(height: Space.l),
          Text(
            'Pick the grade you are practising today.',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.l),
          _GradeCard(
            grade: 'Grade 4',
            title: 'Grade 4 Mathematics',
            subtitle: 'Gr4 Math',
            status: 'Completed',
            statusColor: colors.success,
            statusIcon: Icons.check_circle,
            onClick: () => _pickGrade('grade4'),
            selected: _selectedGrade == 'grade4',
            borderColor: colors.success,
          ),
          const SizedBox(height: Space.m),
          _GradeCard(
            grade: 'Grade 5',
            title: 'Grade 5 Mathematics',
            subtitle: 'Gr5 Math',
            status: 'New',
            statusColor: colors.hint,
            statusIcon: Icons.radar,
            onClick: () => _pickGrade('grade5'),
            selected: _selectedGrade == 'grade5',
            borderColor: colors.hint,
          ),
          const SizedBox(height: Space.m),
          _GradeCard(
            grade: 'Grade 6',
            title: 'Grade 6 Mathematics',
            subtitle: 'Gr6 Math',
            status: 'Coming soon',
            statusColor: colors.tryAgain,
            statusIcon: Icons.hourglass_empty,
            onClick: () => _pickGrade('grade6'),
            selected: _selectedGrade == 'grade6',
            borderColor: colors.tryAgain,
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.onClick,
    required this.selected,
    required this.borderColor,
  });

  final String grade;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onClick;
  final bool selected;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onClick,
        borderRadius: Radii.cardBr,
        child: Container(
          padding: const EdgeInsets.all(Space.l),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: Radii.cardBr,
            border: Border.all(
              color: selected ? borderColor : scheme.outlineVariant,
              width: selected ? 3 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: selected ? borderColor.withAlpha(40) : scheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      grade,
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected ? borderColor : scheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.numbers,
                        size: 20,
                        color: selected ? borderColor : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: text.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.s),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? borderColor : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
