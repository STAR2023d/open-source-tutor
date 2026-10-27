# Hesabu

Free, open-source, offline-first maths practice for Kenyan learners in Grades 4-6,
aligned to the national competency-based curriculum designs (KICD).
Learners practise a skill with examples, questions and games until they show
mastery, then move on.

**Status:** pre-alpha. Grade 4 Numbers: place value and addition are live. Themed UI, teaching pictures, a buddy and onboarding are in.

## Principles
1. Mastery before progress: a learner moves on only after showing mastery.
2. Bloom-tagged questions: Remember, Understand, Apply, Analyze (then Evaluate/Create as challenges).
3. Wrong answers teach: every distractor maps to a known misconception.
4. Local-first and private: no accounts, no tracking, no personal data.
5. Content is data: teachers can contribute lessons through JSON pull requests.

## Repo map
| Path | What |
|---|---|
| `packages/mastery_core` | Pure Dart learning engine and its tests |
| `packages/content_pack` | Skills and questions as JSON (CC BY-SA 4.0) |
| `apps/learner_app` | Flutter app (web PWA + Android) |
| `tools/validate_content.py` | Content quality gate used by CI |
| `docs/` | Curriculum mapping, design system, teaching pictures, buddies and onboarding, architecture decisions |

## Run it
```bash
python3 tools/validate_content.py
cd packages/mastery_core && dart pub get && dart test
cd ../../apps/learner_app
flutter create --platforms=web,android --project-name learner_app .
flutter pub get && flutter run -d chrome
```

## Licences
Code: Apache-2.0 (add `LICENSE`). Content in `packages/content_pack`: CC BY-SA 4.0.
