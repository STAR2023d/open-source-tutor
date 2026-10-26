# Fonts

Hesabu uses **Lexend** (SIL Open Font License), a typeface designed to improve reading fluency.
It is bundled, not downloaded, so the app works offline.

1. Download Lexend from https://fonts.google.com/specimen/Lexend (Download family).
2. Copy `Lexend-Regular.ttf`, `Lexend-Medium.ttf`, `Lexend-SemiBold.ttf`, `Lexend-Bold.ttf`
   into this folder (use the static files).
3. Uncomment the `fonts:` block in `apps/learner_app/pubspec.yaml`.
4. Commit the OFL licence text next to the fonts.

Until then the app uses the platform default font.
