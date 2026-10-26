import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import '../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: ListenableBuilder(
            listenable: theme,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(Space.m),
              children: [
                Text('Look', style: text.titleMedium),
                const SizedBox(height: Space.s),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('Auto')),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark')),
                  ],
                  selected: {theme.mode},
                  onSelectionChanged: (s) => theme.setMode(s.first),
                ),
                const SizedBox(height: Space.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Larger text'),
                  subtitle: const Text('Makes everything easier to read'),
                  value: theme.largeText,
                  onChanged: theme.setLargeText,
                ),
                const Divider(height: Space.xl),
                Text('About', style: text.titleMedium),
                const SizedBox(height: Space.s),
                Text(
                  'Hesabu is free and open source. Your progress stays on this '
                  'device. No account and no personal data.',
                  style: text.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
