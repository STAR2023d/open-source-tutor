# ADR 0002: Mastery rule

Status: accepted (revisit after pilot data).

A skill is mastered when, over the last 10 attempts, accuracy >= 80% and the learner has at least
2 correct answers without hints at each of Remember, Understand, Apply and Analyze.
Evaluate and Create are challenge levels and do not block progress in Grades 4-6.
Constants live in `SkillProgress` and in `tools/validate_content.py`; keep them in sync.
