"""Mutation test: corrupt good questions on purpose and prove the verifier notices.

A corrupted question must either be REJECTED or be labelled human-only
(code could not decide, so a person must look). It may never come out as
"code-verified" while being wrong.
"""
import copy
import random

import pytest

from hesabu_agents.content_io import Repo
from hesabu_agents.llm import TemplateLLM
from hesabu_agents.verifiers import verify_question

from conftest import REPO

SKILLS = ["g4.num.add.regroup", "g4.num.whole.place-value"]
LEVELS = ["remember", "understand", "apply", "analyze"]


def verdict(q, spec):
    q = copy.deepcopy(q)
    q["_requested"] = q["bloom"]
    return verify_question(q, spec, set(), set())


def samples(skill, n=40):
    t, spec = TemplateLLM(seed=99), Repo(REPO).spec(skill)
    for level in LEVELS:
        for _ in range(n):
            q = t._build(skill, level)
            yield q, spec


@pytest.mark.parametrize("skill", SKILLS)
def test_clean_questions_pass(skill):
    for q, spec in samples(skill):
        assert verdict(q, spec).issues == [], q["prompt"]


@pytest.mark.parametrize("skill", SKILLS)
def test_wrong_numeric_answer_is_always_rejected(skill):
    hit = 0
    for q, spec in samples(skill):
        if q["type"] == "numericInput":
            q["answer"] = str(int(q["answer"]) + 1)
            assert verdict(q, spec).issues, q["prompt"]
            hit += 1
    assert hit > 20


@pytest.mark.parametrize("skill", SKILLS)
def test_tampered_check_is_always_rejected(skill):
    hit = 0
    for q, spec in samples(skill):
        chk = q["check"]
        if "equals" in chk:
            chk["equals"] += 1
        elif "digit" in chk:
            chk["digit"] = (chk["digit"] + 1) % 10
        else:
            continue
        assert verdict(q, spec).issues, q["prompt"]
        hit += 1
    assert hit > 20


@pytest.mark.parametrize("skill", SKILLS)
def test_wrong_option_marked_correct_is_never_code_verified(skill):
    rng, hit = random.Random(3), 0
    for q, spec in samples(skill):
        if q["type"] != "multipleChoice":
            continue
        wrong = rng.choice([c for c in q["choices"] if not c.get("correct")])
        for c in q["choices"]:
            c["correct"] = c is wrong
            if c is wrong:
                c.pop("misconception", None); c.pop("feedback", None)
            elif "misconception" not in c:
                c["misconception"], c["feedback"] = "swapped_by_test", "Swapped on purpose by the test."
        r = verdict(q, spec)
        assert r.issues or r.human_only, f"WRONG KEY SLIPPED THROUGH: {q['prompt']}"
        hit += 1
    assert hit > 20


@pytest.mark.parametrize("skill", SKILLS)
def test_numbers_changed_in_prompt_are_rejected(skill):
    for q, spec in samples(skill):
        if q["check"]["kind"] != "expr":
            continue
        g = q["check"]["givens"][0]
        q["prompt"] = q["prompt"].replace(f"{g:,}", f"{g + 7:,}", 1) if f"{g:,}" in q["prompt"] else q["prompt"].replace(str(g), str(g + 7), 1)
        assert verdict(q, spec).issues, q["prompt"]
