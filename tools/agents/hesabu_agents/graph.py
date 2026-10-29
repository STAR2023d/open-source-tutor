"""The LangGraph pipeline.

    plan -> generate -> verify -> critic -> (revise -> verify ...) -> finalize

- plan / verify / finalize are plain code (deterministic).
- generate / critic / revise call the LLM.
- The graph never touches the content pack. It only writes a *proposal* file.
  A human approves questions with `review`, and only `promote` changes the content.
"""
from __future__ import annotations

import itertools
import json
import operator
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated, TypedDict

from langgraph.graph import END, START, StateGraph

from . import prompts
from collections import Counter

from .content_io import CORE_LEVELS, Repo, norm_prompt, question_key
from .llm import LLMClient, LLMError, extract_json
from .verifiers import verify_question


@dataclass
class RunConfig:
    root: Path
    skill_id: str
    per_level: int = 6
    levels: tuple[str, ...] = tuple(CORE_LEVELS)
    max_attempts: int = 3
    use_critic: bool = True
    out_dir: Path | None = None
    buffer: bool = True  # over-generate a little: some drafts will be rejected
    include_pending: bool = True  # count unpromoted proposals so reruns only top up


class GenState(TypedDict, total=False):
    skill_id: str
    plan: dict[str, int]
    drafts: list[dict]
    survivors: list[dict]
    accepted: list[dict]
    rejected: list[dict]
    attempt: int
    shortfall: dict[str, int]
    proposal_path: str
    log: Annotated[list[str], operator.add]


def _remaining(plan: dict[str, int], accepted: list[dict]) -> int:
    have = {lv: 0 for lv in plan}
    for q in accepted:
        have[q["bloom"]] = have.get(q["bloom"], 0) + 1
    return sum(max(0, need - have.get(lv, 0)) for lv, need in plan.items())


def build_graph(llm: LLMClient, cfg: RunConfig):
    repo = Repo(cfg.root)
    skills = repo.skills()
    if cfg.skill_id not in skills:
        raise KeyError(f"unknown skill {cfg.skill_id}. Known: {', '.join(sorted(skills))}")
    skill, spec = skills[cfg.skill_id], repo.spec(cfg.skill_id)
    tids = itertools.count(1)

    # ------------------------------------------------------------ nodes
    def plan(state: GenState) -> dict:
        have = Counter(repo.counts(cfg.skill_id))
        pending = repo.pending(cfg.skill_id, cfg.out_dir) if cfg.include_pending else []
        have.update(q["bloom"] for q in pending)
        need = {lv: max(0, cfg.per_level - have.get(lv, 0)) for lv in cfg.levels}
        need = {lv: n for lv, n in need.items() if n > 0}
        return {"plan": need, "attempt": 0, "accepted": [], "rejected": [], "survivors": [],
                "log": [f"plan: existing+pending {dict(have)} ({len(pending)} pending in proposals/); need {need or 'nothing'}"]}

    def generate(state: GenState) -> dict:
        drafts, log = [], []
        examples = repo.questions(cfg.skill_id)[:2]
        for level, need in state["plan"].items():
            count = need + (max(1, need // 2) if cfg.buffer else 0)
            try:
                reply = extract_json(llm.complete(prompts.GEN_SYSTEM, prompts.gen_user(skill, spec, level, count, examples)))
                items = reply.get("questions", [])
            except LLMError as e:
                log.append(f"generate[{level}]: FAILED {e}")
                continue
            for q in items:
                if isinstance(q, dict):
                    q["_requested"], q["_tid"] = level, f"d{next(tids)}"
                    drafts.append(q)
            log.append(f"generate[{level}]: {len(items)} drafts")
        return {"drafts": drafts, "log": log}

    def verify(state: GenState) -> dict:
        seen_keys, seen_prompts = repo.existing(cfg.skill_id)
        pending = repo.pending(cfg.skill_id, cfg.out_dir) if cfg.include_pending else []
        for q in [*pending, *state.get("accepted", [])]:
            seen_keys.add(question_key(q)); seen_prompts.add(norm_prompt(q["prompt"]))
        survivors, rejected = [], []
        for q in state.get("drafts", []):
            res = verify_question(q, spec, seen_keys, seen_prompts)
            if res.issues:
                rejected.append({"question": q, "issues": res.issues})
                continue
            q["_verification"] = {"status": "human-only" if res.human_only else "code-verified",
                                  "checks": res.checks, "warnings": res.warnings}
            seen_keys.add(question_key(q)); seen_prompts.add(norm_prompt(q["prompt"]))
            survivors.append(q)
        return {"survivors": survivors, "rejected": rejected, "drafts": [],
                "log": [f"verify: {len(survivors)} passed, {len(rejected)} rejected"]}

    def critic(state: GenState) -> dict:
        survivors, rejected = state.get("survivors", []), list(state.get("rejected", []))
        accepted = list(state.get("accepted", []))
        if not survivors:
            return {"log": ["critic: nothing to review"]}
        reviews: dict[str, dict] = {}
        note = "critic: skipped"
        if cfg.use_critic:
            try:
                reply = extract_json(llm.complete(prompts.CRITIC_SYSTEM, prompts.critic_user(skill, survivors)))
                reviews = {r["id"]: r for r in reply.get("reviews", []) if isinstance(r, dict) and "id" in r}
                note = f"critic: reviewed {len(reviews)}/{len(survivors)}"
            except LLMError as e:
                note = f"critic: UNAVAILABLE ({e}); passing on code checks only"
        for q in survivors:
            r = reviews.get(q["_tid"])
            if r is not None and r.get("ok") is False:
                rejected.append({"question": q, "issues": ["critic: " + str(i) for i in r.get("issues", ["not suitable"])]})
            else:
                q["_critic"] = r
                accepted.append(q)
        return {"accepted": accepted, "rejected": rejected, "survivors": [], "log": [note]}

    def revise(state: GenState) -> dict:
        attempt = state.get("attempt", 0) + 1
        drafts, log = [], []
        for item in state["rejected"]:
            q = item["question"]
            if q.get("_requested") not in state["plan"]:
                continue
            try:
                reply = extract_json(llm.complete(prompts.REVISE_SYSTEM, prompts.revise_user(skill, spec, q, item["issues"])))
                fixed = reply.get("questions", [None])[0]
            except (LLMError, IndexError) as e:
                log.append(f"revise: FAILED for {q.get('_tid')}: {e}")
                continue
            if isinstance(fixed, dict):
                fixed["_requested"], fixed["_tid"] = q["_requested"], f"d{next(tids)}"
                drafts.append(fixed)
        log.append(f"revise (attempt {attempt}): {len(drafts)} revised drafts")
        return {"attempt": attempt, "drafts": drafts, "rejected": [], "log": log}

    def route(state: GenState) -> str:
        if state.get("rejected") and state.get("attempt", 0) < cfg.max_attempts and _remaining(state["plan"], state.get("accepted", [])) > 0:
            return "revise"
        return "finalize"

    def finalize(state: GenState) -> dict:
        plan = state["plan"]
        order = {"code-verified": 0, "human-only": 1}
        kept, count = [], {lv: 0 for lv in plan}
        pool = sorted(state.get("accepted", []), key=lambda q: order[q["_verification"]["status"]])
        for q in pool:
            if count.get(q["bloom"], 0) < plan.get(q["bloom"], 0):
                kept.append(q); count[q["bloom"]] += 1
        shortfall = {lv: need - count[lv] for lv, need in plan.items() if need - count[lv] > 0}
        if not kept and not state.get("rejected"):
            return {"shortfall": shortfall,
                    "log": [f"finalize: nothing to review, no file written; shortfall {shortfall or 'none'}"]}
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        out_dir = cfg.out_dir or (cfg.root / "proposals")
        out_dir.mkdir(parents=True, exist_ok=True)
        path, n = out_dir / f"{cfg.skill_id}.{stamp}.json", 1
        while path.exists():  # never overwrite an earlier proposal, even within the same second
            n += 1
            path = out_dir / f"{cfg.skill_id}.{stamp}-{n}.json"
        questions = []
        for q in kept:
            clean = {k: v for k, v in q.items() if not k.startswith("_")}
            clean["_review"] = {"status": "pending", "reviewed_by": None,
                                "verification": q["_verification"]["status"],
                                "checks": q["_verification"]["checks"],
                                "warnings": q["_verification"].get("warnings", []), "critic": q.get("_critic")}
            clean["_tid"] = q["_tid"]
            questions.append(clean)
        rejected = [{"question": {k: v for k, v in r["question"].items() if not k.startswith("_")}, "issues": r["issues"]}
                    for r in state.get("rejected", [])]
        path.write_text(json.dumps({
            "skillId": cfg.skill_id, "generatedAt": stamp, "model": llm.name, "promptVersion": prompts.PROMPT_VERSION,
            "perLevelTarget": cfg.per_level, "shortfall": shortfall, "log": state.get("log", []),
            "questions": questions, "rejected": rejected,
        }, indent=2, ensure_ascii=False) + "\n")
        return {"proposal_path": str(path), "shortfall": shortfall,
                "log": [f"finalize: wrote {len(questions)} questions to {path.name}; shortfall {shortfall or 'none'}"]}

    # ------------------------------------------------------------ wiring
    g = StateGraph(GenState)
    for name, fn in [("plan", plan), ("generate", generate), ("verify", verify), ("critic", critic),
                     ("revise", revise), ("finalize", finalize)]:
        g.add_node(name, fn)
    g.add_edge(START, "plan")
    g.add_conditional_edges("plan", lambda s: "generate" if s["plan"] else "finalize", {"generate": "generate", "finalize": "finalize"})
    g.add_edge("generate", "verify")
    g.add_edge("verify", "critic")
    g.add_conditional_edges("critic", route, {"revise": "revise", "finalize": "finalize"})
    g.add_edge("revise", "verify")
    g.add_edge("finalize", END)
    return g.compile()


def run(llm: LLMClient, cfg: RunConfig) -> GenState:
    return build_graph(llm, cfg).invoke({"skill_id": cfg.skill_id})
