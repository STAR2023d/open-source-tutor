# Hesabu content pipeline (LangGraph)

Drafts new questions with an LLM, **verifies them with plain code**, has a critic review them, and then
requires **a named human** to approve before anything reaches the content pack.

```
plan -> generate -> verify -> critic -+-> finalize  -> proposals/<skill>.<time>.json
              ^                       |
              +------- revise <-------+   (only the rejected drafts, up to --max-attempts)

   review (human)  ->  promote (merge + run validate_content.py, rolled back on failure)
```

## Setup (Linux)
```bash
cd hesabu
python3 -m venv .venv && source .venv/bin/activate
pip install -e "tools/agents[dev]"
python -m pytest tools/agents -q        # 50 tests, no network, no model
```

## Try it with no model at all
```bash
python -m hesabu_agents status
python -m hesabu_agents generate --skill g4.num.add.regroup --per-level 6        # offline TemplateLLM
python -m hesabu_agents review proposals/<file>.json --reviewer "Your Name"
python -m hesabu_agents promote proposals/<file>.json
```

## Use a real model (free options)
Model names and free quotas change, so nothing is hard-coded. Look up a current model first.
```bash
# Local with Ollama (private, free, offline once downloaded)
python -m hesabu_agents generate --skill g4.num.add.regroup --llm openai \
    --base-url http://localhost:11434/v1 --model <your-ollama-model>

# Gemini free tier (key from an environment variable, never in the repo)
export GEMINI_API_KEY=...        # do NOT commit this
python -m hesabu_agents generate --skill g4.num.add.regroup --llm gemini --model <current-gemini-model>
```
The `openai` provider works with any `/chat/completions` server (Ollama, Groq, OpenRouter...).
These two network providers are NOT covered by automated tests; try them on one skill and read the proposal carefully.

## Good to know
- **Busy models are retried.** HTTP 429/5xx are retried with 3, 8, 20 and 45 second waits (and `Retry-After` when given).
- **Reruns top up.** `generate` counts unpromoted proposals (pending or approved) towards the target and the duplicate check,
  so running it again only asks for what is still missing. Use `--no-pending` to ignore them.
  It never overwrites a proposal file, and writes nothing when there is nothing to review.
- **`recheck <proposal>`** re-runs today's verifier on an older proposal file: it repairs known shape problems
  (for example a visual nested as `{"columnAddition": {...}}`), refreshes the checks and warnings, and sends an
  already-approved question back to *pending* if it now has a real problem.
- **Warnings** (for example "carries are visible with the question") never reject a question; they are shown to the reviewer.

## What code verifies, and what it cannot
Every drafted question must carry a `check`. Code re-derives the answer using exact arithmetic (no `eval`):

| Check | Code proves |
|---|---|
| `expr` | the numbers come from the prompt (as often as they are used), the expression equals the answer key, results stay in the skill's range, regrouping is present where required |
| `place_value` | the digit really sits in that place; total value or place name matches the key |
| `digit_place` | only the marked option has the digit in that place |
| visual rules | picture numbers match the prompt and the picture does not print the answer |
| lint | Kenyan currency, sentence length, no very long words; no duplicates |

Questions whose correct option is a sentence (for example "what mistake did Peter make?") get the numbers verified
but are labelled **human-only**: code cannot tell which sentence is right, so you must. The mutation tests
(`tests/test_mutation.py`) corrupt answer keys, checks and prompts on purpose and prove none slips through as
"code-verified".

An LLM critic additionally reviews clarity, reading level, Kenyan context and distractor quality. It can reject
a question but it can never approve one. Only a human can.

## Adding a skill
1. Add the skill to `skills.json` (status `planned`).
2. Add `tools/agents/skill_specs/<skill-id>.json` with `max_value`, `contexts`, `notes` and optionally
   `regroup_required_levels`.
3. Generate with a real model, review every question, promote, then change the skill to `live`.
4. If a new kind of arithmetic needs a new `check` kind, add it to `verifiers.py` with tests and a mutation test.

## Rules
- No learner data is ever sent to a model. Prompts contain only skill descriptions and example questions.
- Never copy text from textbooks, past papers or KICD documents into prompts or content.
- Free-tier providers may log prompts. That is fine for public content, which is why prompts hold nothing private.
- Generated content is CC BY-SA 4.0 like the rest of the content pack.
