"""Regression tests for problems seen on the first run with a real model (Gemini)."""
import copy
import io
import json
import urllib.error

import pytest

from hesabu_agents import llm as llm_mod
from hesabu_agents.graph import RunConfig, run
from hesabu_agents.llm import LLMError, TemplateLLM
from hesabu_agents.review import apply_decisions, load, recheck, save
from hesabu_agents.verifiers import verify_question

SPEC = {"max_value": 9999, "max_result": 10000, "regroup_required_levels": ["apply", "analyze"]}

# Exactly what the real model produced: the visual is nested under its type name.
REAL = {
    "_requested": "remember", "bloom": "remember", "type": "numericInput",
    "prompt": "Work out: 4,568 + 2,175", "answer": "6743",
    "hints": ["Add column by column starting from the ones: 8 + 5 = 13."],
    "explanation": "Add the ones: 8 + 5 = 13. Write 3, carry 1 ten. The answer is 6,743.",
    "visual": {"columnAddition": {"a": 4568, "b": 2175, "showCarries": True, "showResult": False}},
    "check": {"kind": "expr", "givens": [4568, 2175], "expr": "4568+2175", "equals": 6743},
}


def verify(q):
    return verify_question(copy.deepcopy(q), SPEC, set(), set())


# ------------------------------------------------------------------ visuals
def test_nested_visual_is_normalized_not_silently_accepted():
    q = copy.deepcopy(REAL)
    r = verify_question(q, SPEC, set(), set())
    assert q["visual"]["type"] == "columnAddition" and q["visual"]["a"] == 4568
    assert r.issues == []
    assert "visual shape normalized to {type: ...}" in r.checks
    assert not any("None" in c for c in r.checks)          # the old false "visual 'None' consistent"


def test_carries_shown_with_the_question_is_a_warning_for_the_human():
    r = verify(REAL)
    assert r.issues == [] and any("carries are visible" in w for w in r.warnings)


def test_unknown_or_missing_visual_type_is_rejected():
    for bad in ({"a": 1, "b": 2}, {"type": "hologram"}, "columnAddition", {"x": {"a": 1}}):
        q = copy.deepcopy(REAL)
        q["visual"] = bad
        assert any("needs a 'type'" in i for i in verify(q).issues), bad


def test_visual_numbers_must_match_after_normalization():
    q = copy.deepcopy(REAL)
    q["visual"] = {"columnAddition": {"a": 1111, "b": 2222}}
    assert any("must appear in the prompt" in i for i in verify(q).issues)


# --------------------------------------------------------- numeric duplicates
def test_wrong_choice_with_same_value_as_correct_is_rejected():
    q = {"_requested": "apply", "bloom": "apply", "type": "multipleChoice",
         "prompt": "A shopkeeper counted 3,450 shillings in the morning and 2,860 shillings in the afternoon. What was the total?",
         "choices": [{"text": "6,310", "correct": True},
                     {"text": "6310", "misconception": "same_value_other_format", "feedback": "That is the same number."},
                     {"text": "6,210", "misconception": "forgot_tens_carry", "feedback": "Add the carried 1."},
                     {"text": "5,310", "misconception": "forgot_hundreds_carry", "feedback": "Carry 1 thousand."}],
         "hints": ["Add the amounts."], "explanation": "3,450 + 2,860 = 6,310.",
         "check": {"kind": "expr", "givens": [3450, 2860], "expr": "3450+2860", "equals": 6310}}
    assert any("same value as the correct answer" in i for i in verify(q).issues)
    q["choices"][1]["text"] = "6,410"
    assert verify(q).issues == []


# ------------------------------------------------------------------ retries
def http_error(code, retry_after=None):
    hdrs = {"Retry-After": str(retry_after)} if retry_after else {}
    return urllib.error.HTTPError("http://x", code, "busy", hdrs, io.BytesIO(b'{"error":"busy"}'))


class FakeResponse:
    def __init__(self, body): self.body = body
    def read(self): return json.dumps(self.body).encode()
    def __enter__(self): return self
    def __exit__(self, *a): return False


def test_busy_model_is_retried_with_backoff(monkeypatch):
    calls, sleeps = [], []
    def fake_urlopen(req, timeout=0):
        calls.append(1)
        if len(calls) < 3:
            raise http_error(503)
        return FakeResponse({"ok": True})
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(llm_mod.time, "sleep", sleeps.append)
    assert llm_mod._post("http://x", {}, {}) == {"ok": True}
    assert len(calls) == 3 and sleeps == [3, 8]


def test_retry_after_header_is_respected(monkeypatch):
    sleeps, n = [], []
    def fake_urlopen(req, timeout=0):
        n.append(1)
        if len(n) == 1:
            raise http_error(429, retry_after=11)
        return FakeResponse({"ok": 1})
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(llm_mod.time, "sleep", sleeps.append)
    llm_mod._post("http://x", {}, {})
    assert sleeps == [11]


def test_client_errors_are_not_retried_and_giving_up_raises(monkeypatch):
    sleeps = []
    monkeypatch.setattr(llm_mod.time, "sleep", sleeps.append)
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", lambda req, timeout=0: (_ for _ in ()).throw(http_error(400)))
    with pytest.raises(LLMError, match="HTTP 400"):
        llm_mod._post("http://x", {}, {})
    assert sleeps == []
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", lambda req, timeout=0: (_ for _ in ()).throw(http_error(503)))
    with pytest.raises(LLMError, match="HTTP 503"):
        llm_mod._post("http://x", {}, {}, retries=2)
    assert sleeps == [3, 8]


# ------------------------------------------- reruns top up instead of repeating
def test_rerun_only_tops_up_what_is_missing(repo_copy):
    out = repo_copy / "proposals"
    first = run(TemplateLLM(seed=1), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=out))
    n_first = len(json.loads(open(first["proposal_path"]).read())["questions"])
    assert n_first == 8
    second = run(TemplateLLM(seed=2), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=out))
    assert second["plan"] == {} and any("nothing" in l for l in second["log"])
    assert "proposal_path" not in second                           # no empty file, and the first one is untouched
    assert len(json.loads(open(first["proposal_path"]).read())["questions"]) == 8
    third = run(TemplateLLM(seed=2), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=6, out_dir=out))
    assert sum(third["plan"].values()) == 8          # 4 levels x (6 - 2 existing - 2 pending)
    data = load(third["proposal_path"])
    first_prompts = {q["prompt"] for q in load(first["proposal_path"])["questions"]}
    assert not first_prompts & {q["prompt"] for q in data["questions"]}   # no duplicates across proposals


def test_rejected_proposals_do_not_count(repo_copy):
    out = repo_copy / "proposals"
    first = run(TemplateLLM(seed=1), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=out))
    data = load(first["proposal_path"])
    apply_decisions(data, {q["_tid"]: "rejected" for q in data["questions"]}, "Dan")
    save(first["proposal_path"], data)
    again = run(TemplateLLM(seed=3), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=out))
    assert sum(again["plan"].values()) == 4


# ------------------------------------------------------------------ recheck
def test_recheck_repairs_old_proposals_and_reopens_problem_approvals(repo_copy):
    out = repo_copy / "proposals"
    path = run(TemplateLLM(seed=4), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=out))["proposal_path"]
    data = load(path)
    good, bad = data["questions"][0], data["questions"][1]
    for q in (good, bad):
        q["visual"] = {"columnAddition": {"a": 4568, "b": 2175, "showCarries": True, "showResult": False}}
    good.update(prompt="Work out: 4,568 + 2,175", answer="6743", type="numericInput", bloom="remember",
                check={"kind": "expr", "givens": [4568, 2175], "expr": "4568+2175", "equals": 6743},
                explanation="4,568 + 2,175 = 6,743.")
    good.pop("choices", None)
    bad["answer"] = "1"  # wrong key (or MCQ): an approval of a broken question must be reopened
    bad["type"] = "numericInput"
    bad.pop("choices", None)
    bad["check"] = {"kind": "expr", "givens": [4568, 2175], "expr": "4568+2175", "equals": 6743}
    bad.update(prompt="Work out: 4,568 + 2,175 again", bloom="remember")
    apply_decisions(data, {good["_tid"]: "approved", bad["_tid"]: "approved"}, "Dan")
    save(path, data)
    summary = recheck(path, repo_copy)
    after = load(path)["questions"]
    assert summary["reopened"] >= 1 and summary["flagged"] >= 1
    assert after[0]["visual"]["type"] == "columnAddition"                 # structure repaired
    assert after[0]["_review"]["status"] == "approved"                    # still fine, approval kept
    assert after[1]["_review"]["status"] == "pending" and after[1]["_review"]["recheck_issues"]
    assert after[1]["_review"]["reviewed_by"] is None


def test_two_runs_in_the_same_second_never_overwrite(repo_copy):
    out = repo_copy / "proposals"
    a = run(TemplateLLM(seed=1), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=out, include_pending=False))
    b = run(TemplateLLM(seed=9), RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=out, include_pending=False))
    assert a["proposal_path"] != b["proposal_path"]
    assert len(list(out.glob("*.json"))) == 2
