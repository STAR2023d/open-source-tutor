import json

import pytest

from hesabu_agents.content_io import CORE_LEVELS, Repo
from hesabu_agents.graph import RunConfig, build_graph, run
from hesabu_agents.llm import LLMError, TemplateLLM, extract_json
from hesabu_agents.review import apply_decisions, interactive_review, load, promote, save

SKILLS = ["g4.num.add.regroup", "g4.num.whole.place-value"]


@pytest.mark.parametrize("skill", SKILLS)
def test_pipeline_fills_every_level(repo_copy, skill):
    cfg = RunConfig(root=repo_copy, skill_id=skill, per_level=6, out_dir=repo_copy / "proposals")
    state = run(TemplateLLM(seed=7), cfg)
    data = json.loads(open(state["proposal_path"]).read())
    have = Repo(repo_copy).counts(skill)
    by_level = {lv: sum(1 for q in data["questions"] if q["bloom"] == lv) for lv in CORE_LEVELS}
    assert by_level == {lv: 6 - have[lv] for lv in CORE_LEVELS}
    assert data["shortfall"] == {}
    assert all(q["_review"]["status"] == "pending" and q["_review"]["reviewed_by"] is None for q in data["questions"])
    assert all(q["_review"]["checks"] for q in data["questions"])
    # remember/understand/apply are fully code-verified; analyze items with a descriptive
    # correct option are honestly labelled human-only.
    assert all(q["_review"]["verification"] == "code-verified" for q in data["questions"] if q["bloom"] != "analyze")


def test_sabotaged_question_is_rejected_then_repaired(repo_copy):
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=3, out_dir=repo_copy / "proposals", buffer=False)
    state = run(TemplateLLM(seed=2, sabotage_first=True), cfg)
    log = "\n".join(state["log"])
    assert "verify:" in log and "1 rejected" in log
    assert "revise (attempt 1)" in log
    data = json.loads(open(state["proposal_path"]).read())
    assert data["shortfall"] == {}            # the revision repaired it
    assert state["attempt"] == 1


def test_nothing_to_do_when_content_is_complete(repo_copy):
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=2, out_dir=repo_copy / "proposals")
    state = run(TemplateLLM(), cfg)
    assert state["plan"] == {} and "nothing" in state["log"][0]


def test_unknown_skill_is_an_error(repo_copy):
    with pytest.raises(KeyError):
        build_graph(TemplateLLM(), RunConfig(root=repo_copy, skill_id="nope"))


def test_llm_failure_does_not_crash_the_graph(repo_copy):
    class Broken:
        name = "broken"
        def complete(self, system, user):
            raise LLMError("offline")
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=4, out_dir=repo_copy / "proposals")
    state = run(Broken(), cfg)
    assert state["shortfall"] and all("FAILED" in l or "plan" in l or "verify" in l or "critic" in l or "finalize" in l for l in state["log"])


def test_garbage_from_the_model_is_rejected_not_accepted(repo_copy):
    class Garbage:
        name = "garbage"
        def complete(self, system, user):
            return json.dumps({"questions": [{"bloom": "apply", "type": "numericInput", "prompt": "What is 2+2 shillings?",
                                              "answer": "5", "hints": ["x"], "explanation": "Because."}], "reviews": []})
    cfg = RunConfig(root=repo_copy, skill_id="g4.num.add.regroup", per_level=2, levels=("apply",), out_dir=repo_copy / "proposals")
    cfg.per_level = 3
    state = run(Garbage(), cfg)
    data = json.loads(open(state["proposal_path"]).read())
    assert data["questions"] == []            # nothing unverified ever gets through


def test_extract_json_handles_fences_and_noise():
    assert extract_json('Sure!\n```json\n{"a": 1}\n```') == {"a": 1}
    with pytest.raises(LLMError):
        extract_json("no json here")


def make_proposal(root):
    cfg = RunConfig(root=root, skill_id="g4.num.add.regroup", per_level=4, out_dir=root / "proposals")
    return run(TemplateLLM(seed=5), cfg)["proposal_path"]


def test_human_review_gate_and_promote(repo_copy):
    path = make_proposal(repo_copy)
    before = Repo(repo_copy).counts("g4.num.add.regroup")
    with pytest.raises(ValueError):                    # nothing approved yet
        promote(path, repo_copy)
    data = load(path)
    with pytest.raises(ValueError):                    # anonymous approvals are not allowed
        apply_decisions(data, {data["questions"][0]["_tid"]: "approved"}, "  ")
    ids = [q["_tid"] for q in data["questions"]]
    apply_decisions(data, {ids[0]: "approved", ids[1]: "approved", ids[2]: "rejected"}, "Dan")
    save(path, data)
    new_ids = promote(path, repo_copy)
    after = Repo(repo_copy).counts("g4.num.add.regroup")
    assert len(new_ids) == 2 and sum(after.values()) == sum(before.values()) + 2
    promoted = [q for q in Repo(repo_copy).questions("g4.num.add.regroup") if q["id"] in new_ids]
    assert all("check" not in q and not any(k.startswith("_") for k in q) for q in promoted)
    assert load(path)["questions"][0]["_review"]["status"] == "promoted"


def test_promote_rolls_back_when_validator_fails(repo_copy):
    path = make_proposal(repo_copy)
    data = load(path)
    q = data["questions"][0]
    q["choices"] = [{"text": "x", "correct": True}]   # invalid on purpose: validator needs >= 3 choices
    q["type"] = "multipleChoice"
    apply_decisions(data, {q["_tid"]: "approved"}, "Dan")
    save(path, data)
    files = {f: f.read_bytes() for f in Repo(repo_copy).question_files()}
    with pytest.raises(RuntimeError):
        promote(path, repo_copy)
    assert {f: f.read_bytes() for f in Repo(repo_copy).question_files()} == files


def test_interactive_review_saves_each_decision(repo_copy):
    path = make_proposal(repo_copy)
    answers = iter(["a", "r", "s", "q"])
    out = []
    interactive_review(path, "Dan", input_fn=lambda _: next(answers), print_fn=out.append)
    statuses = [q["_review"]["status"] for q in load(path)["questions"]]
    assert statuses[:3] == ["approved", "rejected", "pending"] and "pending" in statuses[3:]


def test_second_promote_gets_fresh_ids(repo_copy):
    for seed in (11, 12):
        cfg = RunConfig(root=repo_copy, skill_id="g4.num.whole.place-value", per_level=3, out_dir=repo_copy / f"p{seed}")
        path = run(TemplateLLM(seed=seed), cfg)["proposal_path"]
        data = load(path)
        apply_decisions(data, {q["_tid"]: "approved" for q in data["questions"][:2]}, "Dan")
        save(path, data)
        promote(path, repo_copy)
    ids = [q["id"] for q in Repo(repo_copy).questions()]
    assert len(ids) == len(set(ids))
