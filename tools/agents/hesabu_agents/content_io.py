"""Reads and writes the content pack. The pipeline never edits it directly:
only `promote` (after human approval) does."""
from __future__ import annotations

import json
import os
from collections import Counter
from pathlib import Path

from .safe_math import ints_in

BLOOM_LEVELS = ["remember", "understand", "apply", "analyze", "evaluate", "create"]
CORE_LEVELS = BLOOM_LEVELS[:4]  # keep in sync with masteryCeiling in mastery_core
DEFAULT_SPEC = {"max_value": 99999, "contexts": [], "regroup_required_levels": []}


def find_repo_root(start: Path | None = None) -> Path:
    p = (start or Path.cwd()).resolve()
    for cand in [p, *p.parents]:
        if (cand / "packages" / "content_pack").is_dir():
            return cand
    raise FileNotFoundError("Run this inside the hesabu repository (packages/content_pack not found).")


def question_key(q: dict) -> tuple:
    return tuple(sorted(ints_in(q.get("prompt", ""))))


def norm_prompt(text: str) -> str:
    return " ".join((text or "").lower().split())


class Repo:
    def __init__(self, root: Path | str):
        self.root = Path(root)
        self.assets = self.root / "packages" / "content_pack" / "assets"

    def grade_dirs(self) -> list[Path]:
        return sorted(p for p in self.assets.iterdir() if (p / "manifest.json").exists())

    def skills(self) -> dict[str, dict]:
        out = {}
        for g in self.grade_dirs():
            manifest = json.loads((g / "manifest.json").read_text())
            for s in json.loads((g / manifest["skills"]).read_text())["skills"]:
                out[s["id"]] = s
        return out

    def question_files(self) -> list[Path]:
        files = []
        for g in self.grade_dirs():
            manifest = json.loads((g / "manifest.json").read_text())
            files += [g / f for f in manifest["questions"]]
        return files

    def questions(self, skill_id: str | None = None) -> list[dict]:
        out = []
        for f in self.question_files():
            for q in json.loads(f.read_text())["questions"]:
                if skill_id is None or q["skillId"] == skill_id:
                    out.append(q)
        return out

    def counts(self, skill_id: str) -> Counter:
        return Counter(q["bloom"] for q in self.questions(skill_id))

    def existing(self, skill_id: str) -> tuple[set, set]:
        qs = self.questions(skill_id)
        return {question_key(q) for q in qs}, {norm_prompt(q["prompt"]) for q in qs}

    def pending(self, skill_id: str, proposals_dir: Path | None = None) -> list[dict]:
        """Proposed questions not yet promoted or rejected. They count towards the target and the
        duplicate check, so re-running `generate` only tops up what is still missing."""
        d = Path(proposals_dir) if proposals_dir else self.root / "proposals"
        out = []
        for f in sorted(d.glob(f"{skill_id}.*.json")) if d.is_dir() else []:
            for q in json.loads(f.read_text()).get("questions", []):
                if q.get("_review", {}).get("status") in ("pending", "approved"):
                    out.append(q)
        return out

    def all_ids(self) -> set[str]:
        return {q["id"] for q in self.questions()}

    def spec(self, skill_id: str) -> dict:
        path = self.root / "tools" / "agents" / "skill_specs" / f"{skill_id}.json"
        spec = dict(DEFAULT_SPEC)
        if path.exists():
            spec.update(json.loads(path.read_text()))
        return spec


def load_dotenv(path: Path) -> list[str]:
    """Load KEY=VALUE lines from a .env file into os.environ (never overriding values already set).
    Returns the NAMES it set (never the values). Tiny on purpose: no extra dependency."""
    path, names = Path(path), []
    if not path.is_file():
        return names
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        if key and key not in os.environ:
            os.environ[key] = value
            names.append(key)
    return names
