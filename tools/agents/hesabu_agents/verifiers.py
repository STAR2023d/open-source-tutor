"""Deterministic verification of generated questions. NO LLM involved.

Trust model: an LLM may draft a question, but a question only passes if plain
code can re-derive the answer from numbers that appear in the prompt.
Anything code cannot verify is labelled "human-only" and needs extra care
from the human reviewer.
"""
from __future__ import annotations

import re
from collections import Counter
from dataclasses import dataclass, field

from .content_io import BLOOM_LEVELS, norm_prompt, question_key
from .safe_math import (
    UnsafeExpression,
    has_carry,
    int_list_in,
    ints_in,
    parse_number,
    safe_eval,
)

PLACES = ["ones", "tens", "hundreds", "thousands", "ten thousands"]
QTYPES = {"multipleChoice", "numericInput"}
_SNAKE = re.compile(r"^[a-z][a-z0-9_]{2,40}$")
_POWERS_OF_TEN = {10**i for i in range(0, 7)}
KNOWN_VISUALS = {"columnAddition", "placeValueChart", "barModel", "numberLine", "fractionBar", "arrayGrid"}


def normalize_visual(v):
    """Repair the one shape real models produce: {"columnAddition": {...}} -> {"type": "columnAddition", ...}."""
    if isinstance(v, dict) and "type" not in v and len(v) == 1:
        ((key, inner),) = v.items()
        if key in KNOWN_VISUALS and isinstance(inner, dict):
            return {"type": key, **inner}, True
    return v, False


@dataclass
class Result:
    issues: list[str] = field(default_factory=list)
    checks: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)  # not rejections: the human decides
    human_only: bool = False


# ------------------------------------------------------------------ schema
def check_schema(q: dict, res: Result) -> None:
    for key in ("bloom", "type", "prompt", "explanation", "hints"):
        if key not in q:
            res.issues.append(f"missing field '{key}'")
    if res.issues:
        return
    if q["bloom"] not in BLOOM_LEVELS:
        res.issues.append(f"unknown bloom level '{q['bloom']}'")
    req = q.get("_requested")
    if req and q["bloom"] != req:
        res.issues.append(f"asked for '{req}' but question is '{q['bloom']}'")
    if q["type"] not in QTYPES:
        res.issues.append(f"unknown type '{q['type']}'")
        return
    if not isinstance(q["prompt"], str) or not (8 <= len(q["prompt"]) <= 400):
        res.issues.append("prompt must be 8-400 characters")
    if not isinstance(q["explanation"], str) or len(q["explanation"]) < 10:
        res.issues.append("explanation too short")
    hints = q["hints"]
    if not isinstance(hints, list) or not (1 <= len(hints) <= 4) or not all(
        isinstance(h, str) and h.strip() for h in hints
    ):
        res.issues.append("needs 1-4 non-empty hints")

    if q["type"] == "multipleChoice":
        ch = q.get("choices")
        if not isinstance(ch, list) or len(ch) != 4:
            res.issues.append("multiple choice needs exactly 4 choices")
            return
        texts = [str(c.get("text", "")).strip().lower() for c in ch]
        if len(set(texts)) != 4 or "" in texts:
            res.issues.append("choices must be distinct and non-empty")
        if sum(1 for c in ch if c.get("correct") is True) != 1:
            res.issues.append("exactly one choice must be correct")
        for c in ch:
            if c.get("correct") is True:
                continue
            if not _SNAKE.match(str(c.get("misconception", ""))):
                res.issues.append(f"wrong choice '{c.get('text')}' needs a snake_case misconception tag")
            if len(str(c.get("feedback", "")).strip()) < 8:
                res.issues.append(f"wrong choice '{c.get('text')}' needs feedback")
    else:
        if parse_number(q.get("answer")) is None:
            res.issues.append("numeric question needs a numeric 'answer'")


# -------------------------------------------------------------------- math
def _correct_choice_text(q: dict) -> str | None:
    for c in q.get("choices", []):
        if c.get("correct") is True:
            return str(c.get("text", ""))
    return None


def _eval_choice_text(text: str):
    s = text.replace(",", "").strip()
    if re.fullmatch(r"[\d\s+\-*/().]+", s) and re.search(r"\d", s):
        try:
            return safe_eval(s)
        except UnsafeExpression:
            return None
    return None


def _digit_at(number: int, place: str) -> int | None:
    p = PLACES.index(place)
    s = str(number)
    idx = len(s) - 1 - p
    return int(s[idx]) if idx >= 0 else None


def _tie_to_answer(q: dict, computed, explanation: str, res: Result, label: str) -> None:
    """The computed value must match the question's answer key."""
    if q["type"] == "numericInput":
        if parse_number(q["answer"]) != computed:
            res.issues.append(f"{label}: answer key {q['answer']} does not match computed {computed}")
        else:
            res.checks.append(f"{label}: answer key matches recomputation")
        return
    text = _correct_choice_text(q) or ""
    as_num = parse_number(text)
    if as_num is not None:
        if as_num != computed:
            res.issues.append(f"{label}: correct choice {text} does not match computed {computed}")
        else:
            dupes = [c.get("text") for c in q.get("choices", [])
                     if c.get("correct") is not True and parse_number(c.get("text")) == computed]
            if dupes:
                res.issues.append(f"{label}: wrong choice {dupes[0]} has the same value as the correct answer")
            else:
                res.checks.append(f"{label}: correct choice matches recomputation")
        return
    if computed.denominator == 1 and int(computed) not in ints_in(explanation):
        res.issues.append(f"{label}: explanation must state the computed value {computed}")
        return
    as_sum = _eval_choice_text(text)
    if as_sum is not None:  # choices are themselves arithmetic, e.g. "2,345 + 4,900"
        if as_sum != computed:
            res.issues.append(f"{label}: correct choice '{text}' evaluates to {as_sum}, not {computed}")
            return
        for c in q.get("choices", []):
            if c.get("correct") is not True and _eval_choice_text(str(c.get("text", ""))) == computed:
                res.issues.append(f"{label}: wrong choice '{c.get('text')}' is also equal to {computed}")
                return
        res.checks.append(f"{label}: correct choice evaluates to the computed value; no wrong choice does")
    else:
        # The numbers are right, but code cannot tell WHICH option expresses them.
        res.human_only = True
        res.checks.append(f"{label}: value verified, but a human must confirm the marked option is the right one")


def check_math(q: dict, spec: dict, res: Result) -> None:
    chk = q.get("check")
    if not isinstance(chk, dict) or "kind" not in chk:
        res.issues.append("missing 'check' (every question must be machine-checkable)")
        return
    kind = chk["kind"]
    prompt_ints = ints_in(q["prompt"])
    max_value = spec.get("max_value", 99999)

    if kind == "none":
        if q["type"] != "multipleChoice" or len(str(chk.get("reason", ""))) < 10:
            res.issues.append("check 'none' needs a reason and is only allowed for multiple choice")
        else:
            res.human_only = True
            res.checks.append("not machine-checkable: human reviewer must verify")
        return

    if kind == "expr":
        givens = chk.get("givens")
        if not isinstance(givens, list) or not givens or not all(isinstance(g, int) and not isinstance(g, bool) for g in givens):
            res.issues.append("check.givens must be a non-empty list of whole numbers")
            return
        have = Counter(int_list_in(q["prompt"]))
        missing = sorted(n for n, c in Counter(givens).items() if have[n] < c)
        if missing:
            res.issues.append(f"givens {missing} do not appear in the prompt (as often as they are used)")
            return
        used = {int(x) for x in re.findall(r"\d+", str(chk.get("expr", "")))}
        stray = [n for n in used if n not in givens and n not in _POWERS_OF_TEN and n > 12]
        if stray:
            res.issues.append(f"expr uses numbers {sorted(stray)} that are not givens")
            return
        try:
            computed = safe_eval(chk["expr"])
        except (UnsafeExpression, KeyError) as e:
            res.issues.append(f"expr cannot be evaluated: {e}")
            return
        if parse_number(chk.get("equals")) != computed:
            res.issues.append(f"expr evaluates to {computed}, not {chk.get('equals')}")
            return
        res.checks.append(f"expr {chk['expr']} = {computed}")
        if any(g > max_value for g in givens) or computed > spec.get("max_result", max_value):
            res.issues.append(f"numbers exceed the allowed range for this skill ({max_value})")
        _tie_to_answer(q, computed, q["explanation"], res, "expr")
        plain_add = re.fullmatch(r"\s*(\d+)\s*\+\s*(\d+)\s*", str(chk["expr"]))
        if plain_add and q["bloom"] in spec.get("regroup_required_levels", []):
            if not has_carry(int(plain_add[1]), int(plain_add[2])):
                res.issues.append(f"'{q['bloom']}' questions on this skill must involve regrouping")
            else:
                res.checks.append("regrouping present")
        return

    if kind == "place_value":
        number, digit, place, ask = (chk.get(k) for k in ("number", "digit", "place", "ask"))
        if not (isinstance(number, int) and 0 <= number <= 99999 and isinstance(digit, int)
                and 0 <= digit <= 9 and place in PLACES and ask in ("place_name", "total_value")):
            res.issues.append("place_value check has invalid fields")
            return
        if number not in prompt_ints or digit not in prompt_ints:
            res.issues.append("number and digit must appear in the prompt")
            return
        if _digit_at(number, place) != digit:
            res.issues.append(f"digit at {place} of {number} is {_digit_at(number, place)}, not {digit}")
            return
        res.checks.append(f"digit {digit} is in the {place} place of {number}")
        if ask == "total_value":
            from fractions import Fraction
            _tie_to_answer(q, Fraction(digit * 10 ** PLACES.index(place)), q["explanation"], res, "total value")
        else:
            text = (_correct_choice_text(q) or "").strip().lower()
            if q["type"] != "multipleChoice" or text != place:
                res.issues.append(f"correct choice must be '{place}'")
            else:
                res.checks.append("correct choice names the place")
        return

    if kind == "digit_place":
        digit, place = chk.get("digit"), chk.get("place")
        if not (isinstance(digit, int) and 0 <= digit <= 9 and place in PLACES) or q["type"] != "multipleChoice":
            res.issues.append("digit_place check needs digit, place and a multiple choice question")
            return
        if digit not in prompt_ints:
            res.issues.append("digit must appear in the prompt")
            return
        ref = chk.get("reference")
        if ref is not None:
            n, d, p = ref.get("number"), ref.get("digit"), ref.get("place")
            if n not in prompt_ints or p not in PLACES or _digit_at(n, p) != d:
                res.issues.append("reference statement in the prompt is wrong")
                return
            res.checks.append(f"reference: {d} is in the {p} place of {n}")
        for c in q["choices"]:
            n = parse_number(c.get("text"))
            if n is None or n.denominator != 1:
                res.issues.append("every choice must be a whole number")
                return
            has = _digit_at(int(n), place) == digit
            if has != (c.get("correct") is True):
                res.issues.append(
                    f"choice {c['text']}: digit {digit} {'is' if has else 'is not'} in the {place} place, "
                    f"but it is marked {'correct' if c.get('correct') else 'wrong'}")
                return
        res.checks.append(f"only the correct choice has {digit} in the {place} place")
        return

    res.issues.append(f"unknown check kind '{kind}'")


# ------------------------------------------------------------------ visuals
def check_visual(q: dict, res: Result) -> None:
    v = q.get("visual")
    if v is None:
        return
    before = len(res.issues)
    if not isinstance(v, dict) or v.get("type") not in KNOWN_VISUALS:
        res.issues.append(f"visual needs a 'type' key with one of {sorted(KNOWN_VISUALS)}")
        return
    prompt_ints = ints_in(q["prompt"])
    reveal = v.get("showWith", "prompt")
    t = v["type"]
    if reveal not in ("prompt", "hint"):
        res.issues.append("visual showWith must be 'prompt' or 'hint'")

    def must_be_in_prompt(nums, label):
        missing = [n for n in nums if n not in prompt_ints]
        if missing:
            res.issues.append(f"visual {label} {missing} must appear in the prompt")

    if t == "columnAddition":
        must_be_in_prompt([v.get("a"), v.get("b")], "numbers")
        if v.get("showResult") and reveal == "prompt":
            res.issues.append("visual would reveal the answer (showResult with showWith 'prompt')")
        elif v.get("showCarries") and reveal == "prompt":
            res.warnings.append("carries are visible with the question, which gives away the regrouping; consider showWith 'hint'")
    elif t == "placeValueChart":
        # A counters picture shown only as a hint may display the answer's own number:
        # the prompt gives the counts, the picture lays them out.
        answer = parse_number(q.get("answer"))
        counters_hint = v.get("mode") == "counters" and reveal == "hint" and q["type"] == "numericInput"
        if not (counters_hint and answer is not None and answer == v.get("value")):
            must_be_in_prompt([v.get("value")], "number")
        if v.get("showValues") and reveal == "prompt" and q["type"] == "numericInput":
            res.issues.append("visual may reveal the answer (showValues with showWith 'prompt')")
    elif t == "barModel":
        nums = {n for p in v.get("parts", []) if isinstance(p, dict) for n in ints_in(str(p.get("value", "")))}
        must_be_in_prompt(sorted(nums), "part values")
        total = str(v.get("total", "?"))
        if q["type"] == "numericInput" and total != "?" and parse_number(total) == parse_number(q.get("answer")):
            res.issues.append("bar model total reveals the answer")
    elif t == "numberLine":
        marks = [m for m in v.get("marks", []) if isinstance(m, dict) and isinstance(m.get("value"), (int, float))]
        must_be_in_prompt([int(m["value"]) for m in marks if float(m["value"]).is_integer()], "marks")
    if len(res.issues) == before:
        res.checks.append(f"visual '{t}' consistent with the prompt")


# --------------------------------------------------------------------- lint
_BAD_CURRENCY = re.compile(r"[$£€]|\bdollars?\b|\bpounds?\b", re.I)


def lint(q: dict, res: Result) -> None:
    text = q["prompt"]
    if _BAD_CURRENCY.search(text + " " + q["explanation"]):
        res.issues.append("use Kenyan shillings, not other currencies")
    sentences = [s for s in re.split(r"[.?!]+", text) if s.strip()]
    words_per = [len(s.split()) for s in sentences] or [0]
    if max(words_per) > 32 or sum(words_per) / len(words_per) > 20:
        res.issues.append("prompt sentences are too long for Grade 4-6 readers")
    if any(len(w) >= 16 for w in re.findall(r"[A-Za-z]+", text)):
        res.issues.append("prompt uses a very long word")


# ------------------------------------------------------------------- driver
def verify_question(q: dict, spec: dict, seen_keys: set, seen_prompts: set) -> Result:
    res = Result()
    if "visual" in q:
        q["visual"], fixed = normalize_visual(q["visual"])
        if fixed:
            res.checks.append("visual shape normalized to {type: ...}")
    check_schema(q, res)
    if res.issues:
        return res
    check_math(q, spec, res)
    if res.issues:
        return res
    check_visual(q, res)
    lint(q, res)
    key, norm = question_key(q), norm_prompt(q["prompt"])
    if (key and key in seen_keys) or norm in seen_prompts:
        res.issues.append("duplicate of an existing or earlier question (same numbers or text)")
    return res
