#!/usr/bin/env python3
"""Regenerate docs/curriculum-mapping.md from the skill files, so the docs never drift.

  python3 tools/curriculum_report.py            # rewrite the doc
  python3 tools/curriculum_report.py --check    # exit 1 if the doc is out of date (used by CI)
"""
import json
import sys
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "packages" / "content_pack" / "assets"
OUT = ROOT / "docs" / "curriculum-mapping.md"

HEADER = """# Curriculum mapping

Source: the KICD primary curriculum designs for Mathematics, Grades 4, 5 and 6 (revised 2024).
Each design has four strands: **Numbers**, **Measurement**, **Geometry** and **Data Handling**.

How we map it:
- One **skill** is one small, testable group of outcomes inside a sub-strand (`g4.num.add.regroup`).
- `kicdRef` points to the design section and outcome letters (for example `Gr4 Math 1.2 (a-d)`).
  `scope` is our short paraphrase of what the outcomes cover. We reference the designs and never copy their text,
  because the designs are copyrighted by KICD.
- `prerequisites` can reach back to earlier grades. A learner unlocks a skill by mastering its prerequisites.
- Strand and sub-strand names follow the design documents. The KICD design documents still say "Competency Based
  Curriculum", while some education news outlets now say CBE. We keep neutral wording so a rename costs nothing.
- Performance levels in the app (Exceeds, Meets, Approaches, Below expectations) are indicative and are not KNEC grading.
- Skills marked **live** have verified questions. Everything else is **planned**.

*This file is generated. Edit the skill JSON files, then run `python3 tools/curriculum_report.py`.*
"""


def render() -> str:
    out = [HEADER]
    total = live = 0
    for folder in sorted(p for p in ASSETS.iterdir() if (p / "manifest.json").exists()):
        manifest = json.loads((folder / "manifest.json").read_text())
        skills = json.loads((folder / manifest["skills"]).read_text())["skills"]
        total += len(skills)
        live += sum(1 for s in skills if s["status"] == "live")
        out.append(f"\n## Grade {manifest['grade']} ({len(skills)} skills)\n")
        strands: "OrderedDict[str, OrderedDict[str, list]]" = OrderedDict()
        for s in skills:
            strands.setdefault(s["strand"], OrderedDict()).setdefault(s["subStrand"], []).append(s)
        for strand, subs in strands.items():
            out.append(f"\n### {strand}\n")
            out.append("| Sub-strand | Skill | Status | KICD | Prerequisites |")
            out.append("|---|---|---|---|---|")
            for sub, items in subs.items():
                for s in items:
                    pre = ", ".join(f"`{p}`" for p in s["prerequisites"]) or "none"
                    mark = "**live**" if s["status"] == "live" else "planned"
                    out.append(f"| {sub} | {s['title']} (`{s['id']}`) | {mark} | {s['kicdRef']} | {pre} |")
    out.insert(1, f"\n**{total} skills mapped, {live} live.**\n")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    text = render()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            print("docs/curriculum-mapping.md is out of date. Run: python3 tools/curriculum_report.py")
            sys.exit(1)
        print("curriculum-mapping.md is up to date")
    else:
        OUT.write_text(text)
        print(f"wrote {OUT.relative_to(ROOT)}")
