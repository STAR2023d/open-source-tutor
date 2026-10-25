# Contributing

Teachers: you do not need to code. Copy a question in
`packages/content_pack/assets/grade4/questions_*.json`, edit it, and open a pull request.
CI checks the answer key, the Bloom coverage and the links between skills.

## Question rules
- Each live skill needs at least 2 questions at Remember, Understand, Apply and Analyze.
- Multiple choice: exactly one correct choice; every wrong choice gets a `misconception` tag
  and a short `feedback` sentence.
- Numeric: `answer` is a plain number string.
- Write for a 9-11 year old. Use Kenyan contexts (shillings, shamba, matatu).
- Do NOT copy text from KICD designs, textbooks or other copyrighted sources. Reference outcomes
  with `kicdRef` and write original questions.

## Code
`dart analyze` and `dart test` in `packages/mastery_core`, `flutter analyze` in `apps/learner_app`.
