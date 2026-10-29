import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/profile_controller.dart';
import '../mascot/mascot.dart';
import '../theme/tokens.dart';
import '../widgets/kind_picker.dart';

/// Three short screens: welcome, how Hesabu works, choose a buddy and nickname.
/// Nothing is sent anywhere. The choices stay on this device.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.profile});

  final ProfileController profile;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();
  late MascotKind _kind = widget.profile.mascot;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _name.text = widget.profile.nickname;
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pageCount - 1;

  Duration get _slide => MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 300);

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      //if animations disabled, use jump to page to avoid the assertion
      if (MediaQuery.of(context).disableAnimations) {
        _pages.jumpToPage((_pages.page ?? 0).round() + 1);
      } else {
        _pages.nextPage(duration: _slide, curve: Curves.easeOut);
      }
    }
  }

  void _back() => _pages.previousPage(duration: _slide, curve: Curves.easeOut);

  void _finish() => widget.profile.completeOnboarding(
        nickname: _name.text,
        mascot: _kind,
      );

  /// Skip keeps the defaults (Tembo, "Champion") and goes straight in.
  void _skip() => widget.profile.completeOnboarding(
        nickname: '',
        mascot: MascotKind.tembo,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: Space.s, right: Space.s),
                    child: _isLast
                        ? const SizedBox(height: 48)
                        : TextButton(
                            onPressed: _skip, child: const Text('Skip')),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _WelcomePage(kind: _kind),
                      _HowItWorksPage(kind: _kind),
                      _ChoosePage(
                        kind: _kind,
                        onKind: (k) => setState(() => _kind = k),
                        name: _name,
                        onDone: _finish,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.m),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: _page == 0
                            ? null
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _back,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back'),
                                ),
                              ),
                      ),
                      Expanded(
                        child: Semantics(
                          label: 'Page ${_page + 1} of $_pageCount',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _pageCount; i++)
                                  AnimatedContainer(
                                    duration: _slide,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: i == _page ? 24 : 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: i == _page
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 128,
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(_isLast ? "Let's go!" : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
        children: children,
      );
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.kind});

  final MascotKind kind;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _PageFrame(children: [
      const SizedBox(height: Space.l),
      Center(
          child: BouncyMascot(kind: kind, mood: MascotMood.cheer, size: 200)),
      const SizedBox(height: Space.l),
      Text('Jambo! Karibu Hesabu.',
          textAlign: TextAlign.center, style: text.headlineMedium),
      const SizedBox(height: Space.m),
      Text(
        'Free maths practice for Grades 4 to 6. Learn at your own pace, '
        'with no account and no cost.',
        textAlign: TextAlign.center,
        style: text.bodyLarge,
      ),
    ]);
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage({required this.kind});

  final MascotKind kind;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _PageFrame(children: [
      Center(child: Mascot(kind: kind, mood: MascotMood.thinking, size: 110)),
      const SizedBox(height: Space.s),
      Text('How Hesabu helps you learn',
          textAlign: TextAlign.center, style: text.headlineMedium),
      const SizedBox(height: Space.l),
      const _Step(
        icon: Icons.stairs,
        title: 'Climb four steps',
        body: 'Every skill has four steps: Recall, Explain, Use it, Think. '
            'Get two right, with no hints, at each step.',
      ),
      const _Step(
        icon: Icons.tips_and_updates_outlined,
        title: 'Hints are friends',
        body: 'Stuck? Ask for a hint. Pictures and clues help, but try '
            'without them when you can.',
      ),
      const _Step(
        icon: Icons.lock_open,
        title: 'Master it, unlock the next',
        body: 'When you master a skill, the next one opens. '
            'Mistakes are how brains grow!',
      ),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: text.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoosePage extends StatelessWidget {
  const _ChoosePage({
    required this.kind,
    required this.onKind,
    required this.name,
    required this.onDone,
  });

  final MascotKind kind;
  final ValueChanged<MascotKind> onKind;
  final TextEditingController name;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _PageFrame(children: [
      Text('Choose your maths buddy',
          textAlign: TextAlign.center, style: text.headlineMedium),
      const SizedBox(height: Space.l),
      KindPicker(selected: kind, onChanged: onKind),
      const SizedBox(height: Space.l),
      TextField(
        controller: name,
        maxLength: 16,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9 '\-]")),
        ],
        decoration: const InputDecoration(
          labelText: 'Your nickname',
          helperText:
              'Use a nickname, not your full name. It stays on this device.',
          helperMaxLines: 2,
        ),
        onSubmitted: (_) => onDone(),
      ),
    ]);
  }
}
