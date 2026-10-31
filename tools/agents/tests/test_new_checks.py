import copy
import random

import pytest

from conftest import REPO
from factories import FACTORIES, samples
from hesabu_agents.content_io import Repo
from hesabu_agents.numwords import from_words, to_words
from hesabu_agents.verifiers import verify_question

SKILLS = list(FACTORIES)


def verdict(q, spec):
    q = copy.deepcopy(q)
    q["_requested"] = q["bloom"]
    return verify_question(q, spec, set(), set())


@pytest.mark.parametrize("skill", SKILLS)
def test_clean_questions_pass(skill):
    spec = Repo(REPO).spec(skill)
    for name, q in samples(skill):
        r = verdict(q, spec)
        assert r.issues == [], (name, q["prompt"], r.issues)
        assert r.checks, name


@pytest.mark.parametrize("skill", SKILLS)
def test_wrong_numeric_answer_is_always_rejected(skill):
    spec, hit = Repo(REPO).spec(skill), 0
    for name, q in samples(skill):
        if q["type"] == "numericInput":
            q["answer"] = str(int(q["answer"]) + 1)
            assert verdict(q, spec).issues, (name, q["prompt"])
            hit += 1
    assert hit > 20


@pytest.mark.parametrize("skill", SKILLS)
def test_tampered_check_fields_are_always_rejected(skill):
    spec, hit = Repo(REPO).spec(skill), 0
    for name, q in samples(skill):
        c = q["check"]
        if "equals" in c:
            c["equals"] += 1
        elif c["kind"] == "division":
            c["dividend"] += 1
        elif c["kind"] == "order":
            c["numbers"][0] += 1
        elif c["kind"] == "words":
            c["number"] += 1
        else:
            continue
        assert verdict(q, spec).issues, (name, q["prompt"])
        hit += 1
    assert hit > 20


@pytest.mark.parametrize("skill", SKILLS)
def test_marking_a_wrong_option_correct_is_always_rejected(skill):
    """For these kinds code CAN check which option is right, so a swapped key must be rejected."""
    spec, rng, hit = Repo(REPO).spec(skill), random.Random(1), 0
    for name, q in samples(skill):
        if q["type"] != "multipleChoice":
            continue
        wrong = rng.choice([c for c in q["choices"] if not c.get("correct")])
        for c in q["choices"]:
            c["correct"] = c is wrong
            if c is wrong:
                c.pop("misconception", None); c.pop("feedback", None)
            elif "misconception" not in c:
                c["misconception"], c["feedback"] = "swapped_by_test", "Swapped on purpose by the test."
        assert verdict(q, spec).issues, (name, q["prompt"])
        hit += 1
    has_mcq = any(q["type"] == "multipleChoice" for _, q in samples(skill, n=1))
    assert hit > 0 or not has_mcq      # skills with only numeric factories have nothing to swap


# --------------------------------------------------------------- specific rules
SUB = Repo(REPO).spec("g4.num.sub.regroup")


def test_subtraction_rules():
    from factories import sub_word
    q = sub_word(random.Random(1))
    assert verdict(q, SUB).issues == [] and "regrouping (borrowing) present" in verdict(q, SUB).checks
    q["prompt"] = "A shop had 5,678 sacks and sold 2,345 sacks. How many are left?"
    q["check"] = {"kind": "expr", "givens": [5678, 2345], "expr": "5678-2345", "equals": 3333}
    q["answer"], q["explanation"] = "3333", "5,678 - 2,345 = 3,333 sacks."
    assert any("regrouping (borrowing)" in i for i in verdict(q, SUB).issues)       # apply level needs a borrow
    q["prompt"] = "A shop had 2,345 sacks and sold 5,678 sacks. How many are left?"
    q["check"] = {"kind": "expr", "givens": [2345, 5678], "expr": "2345-5678", "equals": -3333}
    q["answer"], q["explanation"] = "-3333", "2,345 - 5,678 = -3,333."
    assert any("negative" in i for i in verdict(q, SUB).issues)


def test_multiplication_ranges():
    tens = Repo(REPO).spec("g4.num.mul.tens")
    from factories import mul_tens
    q = mul_tens(random.Random(2))
    q.update(prompt="What is 34 x 25?", answer="850", explanation="34 x 25 = 850.")
    q["check"] = {"kind": "expr", "givens": [34, 25], "expr": "34*25", "equals": 850}
    assert any("multiple of 10" in i for i in verdict(q, tens).issues)
    two = Repo(REPO).spec("g4.num.mul.two-digit")
    q.update(prompt="What is 7 x 25?", answer="175", explanation="7 x 25 = 175.")
    q["check"] = {"kind": "expr", "givens": [7, 25], "expr": "7*25", "equals": 175}
    assert any("outside the allowed range" in i for i in verdict(q, two).issues)


def test_division_rules():
    spec = Repo(REPO).spec("g4.num.div.one-digit")
    from factories import div_remainder, div_quotient
    q = div_remainder(random.Random(3))
    q["check"]["dividend"] = 84; q["prompt"] = "84 mandazi are shared equally among 7 children. How many are left over?"
    q["check"]["divisor"] = 7
    assert any("exact" in i for i in verdict(q, spec).issues)        # asks for a remainder but 84/7 is exact
    q = div_quotient(random.Random(3))
    q.update(prompt="What is 144 divided by 12?", answer="12", explanation="144 / 12 = 12.")
    q["check"] = {"kind": "division", "dividend": 144, "divisor": 12, "ask": "quotient"}
    assert verdict(q, spec).issues                                   # outside Grade 4 range


def test_order_needs_direction_words_and_valid_choices():
    spec = Repo(REPO).spec("g4.num.whole.order-round")
    from factories import order_q
    q = order_q(random.Random(4))
    q["prompt"] = "Put these numbers in order: " + ", ".join(map(str, q["check"]["numbers"])) + "."
    assert any("must say the order" in i for i in verdict(q, spec).issues)
    q = order_q(random.Random(4))
    q["choices"][1]["text"] = "1, 2, 3, 4"
    assert any("same numbers" in i for i in verdict(q, spec).issues)


def test_number_words_round_trip_and_reject_nonsense():
    assert all(from_words(to_words(n)) == n for n in range(0, 100_000))
    assert from_words("twenty twenty") is None and from_words("and five") is None and from_words("five hundred and") is None
    assert from_words("four hundred twenty six") == 426 and from_words("Four-hundred and twenty-six") == 426


def test_words_prompt_must_contain_the_words():
    spec = Repo(REPO).spec("g4.num.whole.read-write")
    from factories import words_to_digits
    q = words_to_digits(random.Random(8))
    q["prompt"] = "Write the number that is two hundred and fifty in digits."
    assert any("must contain the number in words" in i for i in verdict(q, spec).issues) or q["check"]["number"] == 250


# --------------------------------------------------------------------- go live
def test_golive_refuses_until_enough_questions_then_flips_status(repo_copy):
    import json
    from hesabu_agents.review import go_live
    for need in ("g4.num.sub.regroup",):
        with pytest.raises(ValueError, match="not ready"):
            go_live(repo_copy, need)
    # give the skill 4 questions per core level by writing them straight into the copy
    path = repo_copy / "packages/content_pack/assets/grade4/questions_addition.json"
    data = json.loads(path.read_text())
    n = 0
    for lv in ("remember", "understand", "apply", "analyze"):
        for _ in range(4):
            n += 1
            data["questions"].append({"id": f"sub-{n}", "skillId": "g4.num.sub.regroup", "bloom": lv, "type": "numericInput",
                                      "prompt": f"Work out: {n + 10} - 5", "answer": str(n + 5), "hints": ["x"], "explanation": "Subtract."})
    path.write_text(json.dumps(data))
    go_live(repo_copy, "g4.num.sub.regroup")
    skills = json.loads((repo_copy / "packages/content_pack/assets/grade4/skills.json").read_text())["skills"]
    assert next(s for s in skills if s["id"] == "g4.num.sub.regroup")["status"] == "live"
