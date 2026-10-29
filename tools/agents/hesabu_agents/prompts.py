"""Prompts. Every user message carries a TASK_JSON line so that both real models
and the offline TemplateLLM know exactly what is being asked."""
import json

PROMPT_VERSION = "2026-10-v1"

BLOOM_GUIDE = """Bloom's levels for Grade 4-6 maths (the question's `bloom` MUST equal the requested level):
- remember: recall a fact, name a place value, do a direct one-step calculation.
- understand: explain, estimate, show the meaning, say why a step is done.
- apply: use the skill in a new everyday word problem (Kenyan context).
- analyze: compare, find or explain a mistake, spot a pattern, compare two methods."""

GEN_SYSTEM = f"""You write maths practice questions for Kenyan primary learners (Grades 4-6, competency-based curriculum).
Write original questions. Never copy text from textbooks, past papers or curriculum documents.
Reply with ONE JSON object only: {{"questions": [ ... ]}} and no other text.

Each question object:
{{
  "bloom": "remember|understand|apply|analyze",
  "type": "multipleChoice" | "numericInput",
  "prompt": "short, clear, Grade 4-6 reading level, Kenyan context (shillings, shamba, matatu, mandazi)",
  "choices": [ {{"text": "...", "correct": true}}, {{"text": "...", "misconception": "snake_case_tag", "feedback": "one kind sentence that explains the error"}}, ... ],   // multipleChoice only: EXACTLY 4 choices, exactly 1 correct
  "answer": "plain number as text, no units",                                                    // numericInput only
  "hints": ["gentle nudge", "stronger hint"],
  "explanation": "worked solution a child can follow",
  "visual": {{ ... }},                                                                              // optional teaching picture
  "check": {{ ... }}                                                                                // REQUIRED, see below
}}

Every wrong choice must come from a real misconception and carry a snake_case `misconception` tag and a `feedback` sentence.
Use shillings (KES), never dollars. Keep prompts under 3 short sentences.

THE `check` FIELD lets plain code verify your answer. It is mandatory:
- {{"kind":"expr","givens":[numbers that appear in the prompt],"expr":"3648+2975","equals":6623}}
  expr may use + - * / // % ( ) and round_to(x,10), max(), min(). Every number in expr must be a given or a power of ten.
  The result must equal the numeric answer (numericInput), the numeric correct choice, or a number stated in the explanation.
- {{"kind":"place_value","number":27450,"digit":7,"place":"thousands","ask":"total_value"|"place_name"}}
  places: ones, tens, hundreds, thousands, ten thousands. For ask=place_name the correct choice text is the place name.
- {{"kind":"digit_place","digit":4,"place":"ten thousands","reference":{{"number":4365,"digit":6,"place":"tens"}}}}
  for "which number has digit D in place P": only the correct choice has D in P. `reference` is optional.
- {{"kind":"none","reason":"why code cannot check this"}} only for multiple choice. Avoid it: a human must check it by hand.

VISUALS (optional; pictures must never print the answer). The visual object ALWAYS has a "type" key, for example
{{"type":"columnAddition","a":4568,"b":2175,"showCarries":true,"showResult":false,"showWith":"hint"}}
Never nest it as {{"columnAddition": {{...}}}}. Pictures that show carries or counters help a lot, so give them
"showWith":"hint" on remember and understand questions.
columnAddition {{a,b,showCarries,showResult}}, placeValueChart {{value,mode:digits|counters,showLabels,highlight,showValues}},
barModel {{parts:[{{label,value}}],total,totalLabel}}, numberLine {{min,max,step,labelEvery,marks:[{{value,label}}]}}.
Add "showWith":"hint" to reveal a picture only when the learner asks for a hint. Numbers in a visual must appear in the prompt.

{BLOOM_GUIDE}"""

REVISE_SYSTEM = GEN_SYSTEM + """

You are REVISING one question that failed automatic checks. Fix every listed issue, keep the same bloom level,
and reply with {"questions": [ exactly one corrected question ]}."""

CRITIC_SYSTEM = """You are a careful Kenyan primary-school maths teacher reviewing draft questions for Grades 4-6.
For each question decide if it is suitable. Check: (1) the question is clear and unambiguous, with exactly one right answer,
(2) reading level suits Grades 4-6, (3) the Kenyan context is natural and respectful, (4) every wrong choice is a plausible
misconception and its feedback is kind and correct, (5) the picture (if any) does not give the answer away,
(6) the bloom level really matches what the learner must do.
Reply with ONE JSON object only: {"reviews": [{"id": "<_tid>", "ok": true|false, "issues": ["..."]}]}"""


def task(**kw) -> str:
    return "TASK_JSON: " + json.dumps(kw, ensure_ascii=False)


def gen_user(skill: dict, spec: dict, level: str, count: int, examples: list[dict]) -> str:
    lines = [
        f"Write {count} DIFFERENT questions at Bloom level '{level}' for this skill.",
        f"Skill: {skill['title']} (grade {skill['grade']}, strand {skill['strand']}, sub-strand {skill['subStrand']}).",
        f"Largest number allowed: {spec.get('max_value')}. Largest result allowed: {spec.get('max_result', spec.get('max_value'))}.",
    ]
    if spec.get("notes"):
        lines.append("Skill notes: " + spec["notes"])
    if spec.get("contexts"):
        lines.append("Contexts you may use: " + ", ".join(spec["contexts"]))
    if spec.get("regroup_required_levels") and level in spec["regroup_required_levels"]:
        lines.append("Every plain addition MUST need regrouping (a column adding to 10 or more).")
    if examples:
        lines.append("Style examples (do not copy their numbers):\n" + json.dumps(examples, ensure_ascii=False))
    lines.append(task(task="generate", skill_id=skill["id"], level=level, count=count))
    return "\n".join(lines)


def revise_user(skill: dict, spec: dict, q: dict, issues: list[str]) -> str:
    shown = {k: v for k, v in q.items() if not k.startswith("_")}
    return "\n".join([
        f"Skill: {skill['title']}. Level: {q['_requested']}. Largest number: {spec.get('max_value')}.",
        "Problems found by the checker:\n- " + "\n- ".join(issues),
        "Question to fix:\n" + json.dumps(shown, ensure_ascii=False),
        task(task="revise", skill_id=skill["id"], level=q["_requested"], issues=issues),
    ])


def critic_user(skill: dict, qs: list[dict]) -> str:
    shown = [{"_tid": q["_tid"], **{k: v for k, v in q.items() if not k.startswith("_")}} for q in qs]
    return "\n".join([
        f"Skill: {skill['title']} (grade {skill['grade']}).",
        "Questions:\n" + json.dumps(shown, ensure_ascii=False),
        task(task="critique", ids=[q["_tid"] for q in qs]),
    ])
