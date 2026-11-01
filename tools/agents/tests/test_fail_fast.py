import json

import pytest

from hesabu_agents import llm as llm_mod
from hesabu_agents.graph import RunConfig, run
from hesabu_agents.llm import BudgetLLM, LLMUnavailable, TemplateLLM


class Down:
    name = "down"
    calls = 0
    def complete(self, system, user):
        Down.calls += 1
        raise LLMUnavailable("HTTP 429: quota")


def test_a_dead_model_is_called_once_not_once_per_level(repo_copy):
    Down.calls = 0
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=repo_copy / "proposals")
    state = run(Down(), cfg)
    assert Down.calls == 1 and state["aborted"] is True
    assert any("STOPPED" in l for l in state["log"]) and "proposal_path" not in state


def test_call_budget_stops_the_run_and_keeps_finished_work(repo_copy):
    llm = BudgetLLM(TemplateLLM(seed=3), max_calls=1)
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=repo_copy / "proposals", levels=("remember", "apply"))
    state = run(llm, cfg)
    assert llm.calls == 1 and state["aborted"] is True
    data = json.loads(open(state["proposal_path"]).read())      # the one level that finished is kept, code-verified
    assert data["questions"] and all(q["bloom"] == "remember" for q in data["questions"])
    assert any("critic: skipped" in l for l in state["log"])


def test_http_errors_and_network_failures_are_unavailable(monkeypatch):
    import io, urllib.error
    monkeypatch.setattr(llm_mod.time, "sleep", lambda s: None)
    def bad(req, timeout=0):
        raise urllib.error.HTTPError("http://x", 404, "no such model", {}, io.BytesIO(b"{}"))
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", bad)
    with pytest.raises(LLMUnavailable):
        llm_mod._post("http://x", {}, {})
    def down(req, timeout=0):
        raise urllib.error.URLError("Network is unreachable")
    monkeypatch.setattr(llm_mod.urllib.request, "urlopen", down)
    with pytest.raises(LLMUnavailable):
        llm_mod._post("http://x", {}, {}, retries=1)


def test_levels_option_limits_what_is_planned(repo_copy):
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=repo_copy / "proposals", levels=("analyze",))
    assert run(TemplateLLM(seed=1), cfg)["plan"] == {"analyze": 2}


def test_column_addition_picture_is_only_for_addition():
    import copy
    from hesabu_agents.verifiers import verify_question
    spec = {"max_value": 9999, "borrow_required_levels": []}
    q = {"_requested": "remember", "bloom": "remember", "type": "numericInput",
         "prompt": "A farmer harvested 4,325 bags of maize. He sold 1,842 bags. How many bags were left?",
         "answer": "2483", "hints": ["Subtract the bags sold."], "explanation": "4,325 - 1,842 = 2,483.",
         "visual": {"type": "columnAddition", "a": 4325, "b": 1842, "showWith": "hint"},
         "check": {"kind": "expr", "givens": [4325, 1842], "expr": "4325-1842", "equals": 2483}}
    assert any("shows an ADDITION" in i for i in verify_question(copy.deepcopy(q), spec, set(), set()).issues)
    del q["visual"]
    assert verify_question(copy.deepcopy(q), spec, set(), set()).issues == []
    add = dict(q, prompt="A farmer sold 4,325 bags in May and 1,842 bags in June. How many bags is that?",
               answer="6167", explanation="4,325 + 1,842 = 6,167.",
               visual={"type": "columnAddition", "a": 4325, "b": 1842, "showWith": "hint"},
               check={"kind": "expr", "givens": [4325, 1842], "expr": "4325+1842", "equals": 6167})
    assert verify_question(copy.deepcopy(add), spec, set(), set()).issues == []
