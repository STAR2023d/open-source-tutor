import copy

from hesabu_agents.verifiers import verify_question

SPEC = {"max_value": 9999, "max_result": 10000, "regroup_required_levels": ["apply", "analyze"]}

GOOD = {
    "_requested": "apply", "bloom": "apply", "type": "numericInput",
    "prompt": "A shop earned 3,648 shillings on Monday and 2,975 shillings on Tuesday. How much did it earn altogether?",
    "answer": "6623", "hints": ["Add the two numbers."],
    "explanation": "3,648 + 2,975 = 6,623.",
    "check": {"kind": "expr", "givens": [3648, 2975], "expr": "3648+2975", "equals": 6623},
}


def run(q, spec=SPEC):
    return verify_question(q, spec, set(), set())


def mutated(**changes):
    q = copy.deepcopy(GOOD)
    for k, v in changes.items():
        q[k] = v
    return q


def test_good_question_passes_and_records_checks():
    r = run(GOOD)
    assert r.issues == [] and not r.human_only
    assert any("recomputation" in c for c in r.checks) and "regrouping present" in r.checks


def test_wrong_answer_key_is_caught():
    r = run(mutated(answer="6613"))
    assert any("does not match computed" in i for i in r.issues)


def test_wrong_equals_is_caught():
    q = mutated(); q["check"]["equals"] = 6624
    assert any("evaluates to" in i for i in run(q).issues)


def test_numbers_must_come_from_the_prompt():
    q = mutated(); q["check"]["givens"] = [3648, 9999]
    assert any("do not appear in the prompt" in i for i in run(q).issues)


def test_expr_cannot_smuggle_in_other_numbers():
    q = mutated(); q["check"]["expr"] = "3648+2975+37"; q["check"]["equals"] = 6660; q["answer"] = "6660"
    assert any("not givens" in i for i in run(q).issues)


def test_missing_check_is_rejected():
    q = mutated(); del q["check"]
    assert any("missing 'check'" in i for i in run(q).issues)


def test_range_and_regrouping_rules():
    q = mutated(prompt="Add 3,452 and 2,314 to find the total number of mangoes sold.", answer="5766",
                explanation="3,452 + 2,314 = 5,766.")
    q["check"] = {"kind": "expr", "givens": [3452, 2314], "expr": "3452+2314", "equals": 5766}
    assert any("regrouping" in i for i in run(q).issues)
    big = mutated(prompt="Add 9,999 and 9,999 to find the number.", answer="19998", explanation="9,999 + 9,999 = 19,998.")
    big["check"] = {"kind": "expr", "givens": [9999], "expr": "9999+9999", "equals": 19998}
    assert any("exceed" in i for i in run(big).issues)


def test_bloom_must_match_request():
    assert any("asked for" in i for i in run(mutated(bloom="remember")).issues)


def test_visual_may_not_leak_or_disagree():
    q = mutated(visual={"type": "columnAddition", "a": 3648, "b": 2975, "showResult": True})
    assert any("reveal the answer" in i for i in run(q).issues)
    q = mutated(visual={"type": "columnAddition", "a": 1111, "b": 2222, "showResult": False})
    assert any("must appear in the prompt" in i for i in run(q).issues)


def test_duplicates_rejected():
    from hesabu_agents.content_io import norm_prompt, question_key
    r = verify_question(GOOD, SPEC, {question_key(GOOD)}, set())
    assert any("duplicate" in i for i in r.issues)


def test_lint_flags_dollars():
    q = mutated(prompt="A shop earned $3,648 on Monday and 2,975 shillings on Tuesday. How much altogether?")
    assert any("shillings" in i for i in run(q).issues)


def mcq_place(correct_text="Hundreds"):
    return {
        "_requested": "remember", "bloom": "remember", "type": "multipleChoice",
        "prompt": "In the number 5,382, what is the place value of the digit 3?",
        "choices": [
            {"text": correct_text, "correct": True},
            {"text": "Tens", "misconception": "off_by_one_place", "feedback": "Count from the right."},
            {"text": "Thousands", "misconception": "off_by_one_place", "feedback": "The 5 is in the thousands."},
            {"text": "300", "misconception": "confuses_place_and_total_value", "feedback": "That is the total value."},
        ],
        "hints": ["Start from the ones place."], "explanation": "The 3 is in the hundreds place.",
        "check": {"kind": "place_value", "number": 5382, "digit": 3, "place": "hundreds", "ask": "place_name"},
    }


def test_place_value_check():
    assert run(mcq_place()).issues == []
    assert any("correct choice must be" in i for i in run(mcq_place("Ones")).issues)
    q = mcq_place(); q["check"]["place"] = "tens"
    assert any("digit at tens" in i for i in run(q).issues)


def test_choices_need_misconception_tags():
    q = mcq_place(); del q["choices"][1]["misconception"]
    assert any("misconception" in i for i in run(q).issues)


def test_digit_place_requires_only_correct_choice_to_match():
    q = {"_requested": "remember", "bloom": "remember", "type": "multipleChoice",
         "prompt": "Which number has the digit 4 in the hundreds place?",
         "choices": [{"text": "12,430", "correct": True},
                     {"text": "14,305", "misconception": "wrong_place_identified", "feedback": "The 4 is elsewhere."},
                     {"text": "40,152", "misconception": "wrong_place_identified", "feedback": "The 4 is elsewhere."},
                     {"text": "51,204", "misconception": "wrong_place_identified", "feedback": "The 4 is elsewhere."}],
         "hints": ["Hundreds is the third place."], "explanation": "Only 12,430 has 4 in the hundreds place.",
         "check": {"kind": "digit_place", "digit": 4, "place": "hundreds"}}
    assert run(q, {"max_value": 99999}).issues == []          # only 12,430 has a 4 in the hundreds place
    q["choices"][1]["text"] = "14,405"                          # now a wrong choice ALSO has 4 in the hundreds place
    assert any("digit 4 is in the hundreds place" in i for i in run(q, {"max_value": 99999}).issues)


def test_none_check_is_human_only():
    q = mcq_place(); q["check"] = {"kind": "none", "reason": "Needs a teacher to judge the wording."}
    r = run(q)
    assert r.issues == [] and r.human_only
