# Content runbook: taking a skill from "planned" to "live"

Do one skill at a time, or several skills in one `generate` call. A skill goes live when every core
Bloom level (remember, understand, apply, analyze) has at least 4 reviewed questions. Aim for 6.

```bash
cd hesabu && source .venv/bin/activate
python -m hesabu_agents status --grade 4          # what is missing

# 1. Draft. Busy models are retried; reruns only top up what is missing.
python -m hesabu_agents generate --skill g4.num.sub.regroup --per-level 6 \
    --llm gemini --model <current-gemini-model>

# 2. Review every question yourself (see the checklist below).
python -m hesabu_agents review proposals/<file>.json --reviewer "Your Name"

# 3. Publish approved questions into the content pack (validator runs, rolled back on failure).
python -m hesabu_agents promote proposals/<file>.json

# 4. When the skill has enough questions, switch it on.
python -m hesabu_agents golive --skill g4.num.sub.regroup

# 5. Check, then commit (skills, questions and the regenerated doc).
python3 tools/validate_content.py && python3 tools/curriculum_report.py --check
git add -A && git commit -m "Add verified questions for g4.num.sub.regroup"
```

## Reviewer checklist (you are the quality gate)
Code proves the maths is right. Only you can judge whether it is good teaching.
1. Is the question clear to a 9-10 year old, with exactly one sensible answer?
2. Is the Bloom level honest? A one-step word problem is usually "apply", not "remember".
3. Is every wrong choice a mistake a real child makes, and is its feedback kind and correct?
4. Does the picture help without giving the answer away? Scaffold pictures belong with hints.
5. Is the context natural and respectful (shillings, shamba, matatu)? Nothing unsafe or stereotyped.
6. Anything marked **human-only** cannot be checked by code. Solve it yourself.
7. Are the numbers inside the Grade 4 scope for this skill? (The skill's `scope` line says what it covers.)

## What the checks cover
`expr` (arithmetic, rounding), `place_value`, `digit_place`, `division` (quotient, remainder, "9 remainder 2"),
`order` (ascending and descending lists), `words` (British number words both ways). Per-skill limits live in
`tools/agents/skill_specs/<skill>.json`: number ranges, whether regrouping or borrowing is required, divisor
and dividend limits, multiples of 10 for "multiply by tens".

## When a skill needs a new kind of check
Fractions, decimals, geometry and measurement need new checks (see `tools/agents/README.md`). Add the check with
tests and a mutation test first, then generate. Skills without a check kind can still use `kind: none`, which is
always labelled human-only.
