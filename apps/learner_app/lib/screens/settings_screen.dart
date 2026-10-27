import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/profile_controller.dart';
import '../mascot/mascot.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import '../widgets/kind_picker.dart';
import 'gallery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.theme, required this.profile});

  final ThemeController theme;
  final ProfileController profile;

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
                Text('Your buddy', style: text.titleMedium),
                const SizedBox(height: Space.s),
                _BuddySection(profile: profile),
                const Divider(height: Space.xl),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.waving_hand_outlined),
                  title: const Text('Show the welcome again'),
                  onTap: () {
                    // Close Settings first: the welcome replaces the home screen.
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    profile.replayWelcome();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.draw_outlined),
                  title: const Text('Picture gallery'),
                  subtitle: const Text('All the teaching pictures, for teachers and contributors'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const GalleryScreen(),
                  )),
                ),
                const Divider(height: Space.xl),
                Text('About', style: text.titleMedium),
                const SizedBox(height: Space.s),
                Text(
                  'Hesabu is free and open source. Your progress, buddy and '
                  'nickname stay on this device. No account and no personal data.',
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

class _BuddySection extends StatefulWidget {
  const _BuddySection({required this.profile});

  final ProfileController profile;

  @override
  State<_BuddySection> createState() => _BuddySectionState();
}

class _BuddySectionState extends State<_BuddySection> {
  late MascotKind _kind = widget.profile.mascot;
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.nickname);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.profile.save(nickname: _name.text, mascot: _kind);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KindPicker(selected: _kind, onChanged: (k) => setState(() => _kind = k)),
        const SizedBox(height: Space.m),
        TextField(
          controller: _name,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9 '\-]")),
          ],
          decoration: const InputDecoration(
            labelText: 'Your nickname',
            helperText: 'Use a nickname, not your full name.',
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: Space.s),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: _save, child: const Text('Save')),
        ),
      ],
    );
  }
}
