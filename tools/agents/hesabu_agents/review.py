"""Human review and promotion. This is the only place content can change."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from .content_io import BLOOM_LEVELS, Repo, norm_prompt, question_key
from .verifiers import verify_question

STATUSES = ("pending", "approved", "rejected")


def load(path: Path) -> dict:
    return json.loads(Path(path).read_text())


def save(path: Path, data: dict) -> None:
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def apply_decisions(data: dict, decisions: dict[str, str], reviewer: str) -> dict:
    """decisions maps _tid -> 'approved' | 'rejected'. A reviewer name is required."""
    if not reviewer.strip():
        raise ValueError("a reviewer name is required")
    for q in data["questions"]:
        d = decisions.get(q["_tid"])
        if d is None:
            continue
        if d not in ("approved", "rejected"):
            raise ValueError(f"bad decision {d}")
        q["_review"]["status"] = d
        q["_review"]["reviewed_by"] = reviewer.strip()
    return data


def show(q: dict, n: int, total: int) -> str:
    lines = [f"\n--- Question {n}/{total}  [{q['bloom']}]  {q['_review']['verification'].upper()} ---", q["prompt"]]
    if q["type"] == "multipleChoice":
        for i, c in enumerate(q["choices"]):
            tag = "  <-- CORRECT" if c.get("correct") else f"   (misconception: {c.get('misconception')}) {c.get('feedback')}"
            lines.append(f"  {'ABCD'[i]}) {c['text']}{tag}")
    else:
        lines.append(f"  answer: {q['answer']}")
    lines += [f"hints: {q['hints']}", f"explanation: {q['explanation']}"]
    if q.get("visual"):
        lines.append(f"visual: {json.dumps(q['visual'])}")
    lines.append("code checks: " + "; ".join(q["_review"]["checks"]))
    for w in q["_review"].get("warnings", []):
        lines.append(f"WARNING: {w}")
    for i in q["_review"].get("recheck_issues", []):
        lines.append(f"!! RECHECK FOUND A PROBLEM: {i}")
    crit = q["_review"].get("critic")
    if crit and crit.get("issues"):
        lines.append(f"critic notes: {crit['issues']}")
    if q["_review"]["verification"] == "human-only":
        lines.append("!! Code could NOT verify this one. Solve it yourself before approving.")
    return "\n".join(lines)


def interactive_review(path: Path, reviewer: str, input_fn=input, print_fn=print) -> dict:
    data = load(path)
    pending = [q for q in data["questions"] if q["_review"]["status"] == "pending"]
    for i, q in enumerate(pending, 1):
        print_fn(show(q, i, len(pending)))
        while True:
            ans = input_fn("[a]pprove  [r]eject  [s]kip  [q]uit > ").strip().lower()
            if ans in ("a", "r", "s", "q"):
                break
        if ans == "q":
            break
        if ans in ("a", "r"):
            apply_decisions(data, {q["_tid"]: "approved" if ans == "a" else "rejected"}, reviewer)
            save(path, data)  # save after every decision so nothing is lost
    return data


def _slug(skill_id: str) -> str:
    return skill_id.replace(".", "-")


def promote(path: Path, root: Path) -> list[str]:
    """Merge approved questions into the content pack, then run the validator.
    On any validation failure everything is rolled back."""
    data, repo = load(path), Repo(root)
    approved = [q for q in data["questions"] if q["_review"]["status"] == "approved" and q["_review"].get("reviewed_by")]
    if not approved:
        raise ValueError("no approved questions (approve some with `review` first)")
    skill_id = data["skillId"]
    target, manifest_path = None, None
    for g in repo.grade_dirs():
        manifest = json.loads((g / "manifest.json").read_text())
        if skill_id in {s["id"] for s in json.loads((g / manifest["skills"]).read_text())["skills"]}:
            manifest_path = g / "manifest.json"
            for f in manifest["questions"]:
                if any(q["skillId"] == skill_id for q in json.loads((g / f).read_text())["questions"]):
                    target = g / f
            if target is None:
                target = g / f"questions_{_slug(skill_id)}.json"
            break
    if target is None:
        raise KeyError(f"skill {skill_id} not found in any manifest")

    backups = {p: p.read_bytes() if p.exists() else None for p in (target, manifest_path)}
    try:
        existing = json.loads(target.read_text()) if target.exists() else {"questions": []}
        ids = repo.all_ids()
        new_ids = []
        for q in approved:
            n = 1
            while f"{_slug(skill_id)}-{n:03d}" in ids:
                n += 1
            qid = f"{_slug(skill_id)}-{n:03d}"
            ids.add(qid)
            clean = {"id": qid, "skillId": skill_id}
            clean.update({k: v for k, v in q.items() if not k.startswith("_") and k != "check"})
            existing["questions"].append(clean)
            new_ids.append(qid)
        target.write_text(json.dumps(existing, indent=2, ensure_ascii=False) + "\n")
        manifest = json.loads(manifest_path.read_text())
        if target.name not in manifest["questions"]:
            manifest["questions"].append(target.name)
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        validator = Path(root) / "tools" / "validate_content.py"
        r = subprocess.run([sys.executable, str(validator)], capture_output=True, text=True, cwd=root)
        if r.returncode != 0:
            raise RuntimeError("content validator failed, rolled back:\n" + r.stdout + r.stderr)
    except Exception:
        for p, content in backups.items():
            if content is None:
                p.unlink(missing_ok=True)
            else:
                p.write_bytes(content)
        raise
    for q in data["questions"]:
        if q["_review"]["status"] == "approved":
            q["_review"]["status"] = "promoted"
    save(path, data)
    return new_ids


def status_table(root: Path, target: int = 6) -> str:
    repo = Repo(root)
    rows = ["skill".ljust(34) + "status".ljust(9) + "  ".join(l[:4].ljust(5) for l in BLOOM_LEVELS[:4])]
    for sid, s in repo.skills().items():
        c = repo.counts(sid)
        cells = "  ".join((f"{c.get(l, 0)}/{target}").ljust(5) for l in BLOOM_LEVELS[:4])
        rows.append(sid.ljust(34) + s.get("status", "").ljust(9) + cells)
    return "\n".join(rows)


def recheck(path: Path, root: Path) -> dict:
    """Re-run today's verifier on an older proposal (for example after the verifier improved).
    Structural repairs are applied; anything that now fails is flagged, and an already-approved
    question with a problem goes back to 'pending' so a human looks again."""
    data, repo = load(path), Repo(root)
    spec = repo.spec(data["skillId"])
    keys, prompts = repo.existing(data["skillId"])
    summary = {"checked": 0, "flagged": 0, "warnings": 0, "reopened": 0}
    for q in data["questions"]:
        rv = q["_review"]
        if rv["status"] in ("promoted", "rejected"):
            continue
        probe = {k: v for k, v in q.items() if not k.startswith("_")}
        probe["_requested"] = probe["bloom"]
        res = verify_question(probe, spec, keys, prompts)
        if "visual" in probe:
            q["visual"] = probe["visual"]
        rv["checks"], rv["warnings"] = res.checks, res.warnings
        rv["verification"] = "human-only" if res.human_only else "code-verified"
        summary["checked"] += 1
        summary["warnings"] += len(res.warnings)
        if res.issues:
            rv["recheck_issues"] = res.issues
            summary["flagged"] += 1
            if rv["status"] == "approved":
                rv["status"], rv["reviewed_by"] = "pending", None
                summary["reopened"] += 1
        else:
            rv.pop("recheck_issues", None)
        keys.add(question_key(probe))
        prompts.add(norm_prompt(probe["prompt"]))
    save(path, data)
    return summary
