#!/usr/bin/env python3
"""Validate Hesabu content packs. Run: python3 tools/validate_content.py

Why this exists: content is written by humans and AI agents. A wrong answer
key or a broken prerequisite link hurts a child's learning, so we check the
rules mechanically on every pull request.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "packages" / "content_pack" / "assets"
BLOOM = ["remember", "understand", "apply", "analyze", "evaluate", "create"]
CORE_LEVELS = BLOOM[:4]  # must match masteryCeiling in mastery_core
MIN_PER_LEVEL = 2
errors, warnings = [], []

# Visual types the app can draw, with required numeric/list params.
# Keep in sync with apps/learner_app/lib/visuals/visual_factory.dart
VISUALS = {
    "placeValueChart": {"value": (0, 99999)},
    "columnAddition": {"a": (0, 9999), "b": (0, 9999)},
    "barModel": {},
    "numberLine": {"min": None, "max": None, "step": None},
    "fractionBar": {"numerator": (0, 99), "denominator": (1, 12)},
    "arrayGrid": {"rows": (1, 12), "cols": (1, 12)},
}


def check_visual(qid, q):
    v = q.get("visual")
    if v is None:
        return
    vtype = v.get("type")
    if vtype not in VISUALS:
        err(f"{qid}: unknown visual type {vtype}")
        return
    if v.get("showWith", "prompt") not in ("prompt", "hint"):
        err(f"{qid}: showWith must be 'prompt' or 'hint'")
    if v.get("showWith") == "hint" and not q.get("hints"):
        err(f"{qid}: visual is shown with a hint but the question has no hints")
    for key, rng in VISUALS[vtype].items():
        val = v.get(key)
        if not isinstance(val, (int, float)) or isinstance(val, bool):
            err(f"{qid}: visual '{vtype}' needs numeric '{key}'")
        elif rng and not (rng[0] <= val <= rng[1]):
            err(f"{qid}: visual '{vtype}' '{key}' must be in {rng[0]}..{rng[1]}")
    if vtype == "barModel":
        parts = v.get("parts", [])
        if len(parts) < 2 or any("label" not in x or "value" not in x for x in parts):
            err(f"{qid}: barModel needs >= 2 parts with label and value")
    if vtype == "numberLine":
        if isinstance(v.get("min"), (int, float)) and isinstance(v.get("max"), (int, float)):
            if v["max"] <= v["min"]:
                err(f"{qid}: numberLine max must be greater than min")
        if isinstance(v.get("step"), (int, float)) and v["step"] <= 0:
            err(f"{qid}: numberLine step must be > 0")


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def check_grade(folder: Path):
    manifest = json.loads((folder / "manifest.json").read_text())
    skills = json.loads((folder / manifest["skills"]).read_text())["skills"]
    questions = []
    for qf in manifest["questions"]:
        questions += json.loads((folder / qf).read_text())["questions"]

    ids = [s["id"] for s in skills]
    if len(ids) != len(set(ids)):
        err(f"{folder.name}: duplicate skill ids")
    skill_by_id = {s["id"]: s for s in skills}

    for s in skills:
        for p in s.get("prerequisites", []):
            if p not in skill_by_id:
                err(f"skill {s['id']}: unknown prerequisite {p}")

    # cycle check (depth-first search)
    state = {}

    def visit(sid):
        if state.get(sid) == 1:
            err(f"prerequisite cycle through {sid}")
            return
        if state.get(sid) == 2:
            return
        state[sid] = 1
        for p in skill_by_id[sid].get("prerequisites", []):
            if p in skill_by_id:
                visit(p)
        state[sid] = 2

    for sid in skill_by_id:
        visit(sid)

    qids = [q["id"] for q in questions]
    if len(qids) != len(set(qids)):
        err(f"{folder.name}: duplicate question ids")

    per_skill = {}
    for q in questions:
        qid = q.get("id", "?")
        if q.get("skillId") not in skill_by_id:
            err(f"{qid}: unknown skillId {q.get('skillId')}")
            continue
        if q.get("bloom") not in BLOOM:
            err(f"{qid}: invalid bloom level {q.get('bloom')}")
            continue
        if not q.get("explanation"):
            err(f"{qid}: missing explanation")
        check_visual(qid, q)
        if not q.get("hints"):
            warn(f"{qid}: no hints")
        per_skill.setdefault(q["skillId"], {}).setdefault(q["bloom"], 0)
        per_skill[q["skillId"]][q["bloom"]] += 1

        if q["type"] == "multipleChoice":
            ch = q.get("choices", [])
            if len(ch) < 3:
                err(f"{qid}: needs at least 3 choices")
            if sum(1 for c in ch if c.get("correct")) != 1:
                err(f"{qid}: must have exactly one correct choice")
            for c in ch:
                if not c.get("correct") and not c.get("misconception"):
                    warn(f"{qid}: wrong choice '{c['text']}' has no misconception tag")
        elif q["type"] == "numericInput":
            try:
                float(q["answer"])
            except (KeyError, ValueError):
                err(f"{qid}: numeric answer missing or not a number")
        else:
            err(f"{qid}: unknown type {q['type']}")

    for s in skills:
        if s.get("status") == "live":
            counts = per_skill.get(s["id"], {})
            for lvl in CORE_LEVELS:
                if counts.get(lvl, 0) < MIN_PER_LEVEL:
                    err(f"live skill {s['id']}: needs >= {MIN_PER_LEVEL} questions at '{lvl}' (has {counts.get(lvl, 0)})")
    print(f"{folder.name}: {len(skills)} skills, {len(questions)} questions")


for g in sorted(p for p in ROOT.iterdir() if p.is_dir()):
    check_grade(g)

for w in warnings:
    print("WARN ", w)
for e in errors:
    print("ERROR", e)
sys.exit(1 if errors else 0)
