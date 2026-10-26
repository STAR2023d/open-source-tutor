# Design system

**Audience:** learners aged about 9-12, often on cheap Android phones, sometimes outdoors in bright sun.

## Principles
1. Calm and encouraging: wrong answers are amber ("not quite yet"), never red.
2. Never colour alone: every state also has an icon and words.
3. Big and forgiving: tap targets are at least 56 dp; text is larger than Material defaults.
4. Readable: Lexend font, 18 px body, line height 1.5, max line width 720 dp.
5. Respect the user: system text size, light/dark mode and reduced motion are honoured.
6. Offline-first: fonts and assets are bundled; nothing is fetched at runtime.

## Where things live
| File | Purpose |
|---|---|
| `lib/theme/tokens.dart` | Spacing, radii, tap-target and width constants |
| `lib/theme/app_theme.dart` | Material 3 theme from one seed colour; light and dark |
| `lib/theme/hesabu_colors.dart` | Semantic colours: success, try-again, hint, curriculum strands |
| `lib/theme/theme_controller.dart` | Theme mode and larger-text setting, saved on device |
| `lib/widgets/` | ChoiceTile, BloomLadder, FeedbackCard, MasteryBadge, SkillCard, SoftCard |

## Rules for contributors
- No hard-coded colours or font sizes in screens. Use `Theme.of(context)` or `HesabuColors.of(context)`.
- No magic spacing numbers. Use `Space.*` and `Radii.*`.
- New widgets need a widget test in light and dark mode.
- Check contrast (WCAG AA, 4.5:1 for text) and test with the system font scale at 200%.
- Test with TalkBack on Android before releasing UI changes.
