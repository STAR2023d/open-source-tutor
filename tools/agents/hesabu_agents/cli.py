from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from .content_io import find_repo_root, load_dotenv
from .graph import RunConfig, run
from .llm import GeminiLLM, LLMError, OpenAICompatibleLLM, TemplateLLM
from .review import interactive_review, promote, recheck, status_table


def make_llm(args):
    if args.llm == "template":
        return TemplateLLM(seed=args.seed)
    model = args.model or os.environ.get("HESABU_MODEL")
    if not model:
        raise LLMError("pass --model (or set HESABU_MODEL). Model names change, so we do not hard-code one.")
    if args.llm == "gemini":
        return GeminiLLM(model)
    base = args.base_url or os.environ.get("HESABU_BASE_URL")
    if not base:
        raise LLMError("pass --base-url (for local Ollama: http://localhost:11434/v1)")
    return OpenAICompatibleLLM(base, model)


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="hesabu_agents", description="Hesabu content pipeline")
    sub = p.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("generate", help="draft, verify and critique new questions into proposals/")
    g.add_argument("--skill", required=True)
    g.add_argument("--per-level", type=int, default=6, help="target questions per Bloom level")
    g.add_argument("--llm", choices=["template", "openai", "gemini"], default="template")
    g.add_argument("--model")
    g.add_argument("--base-url")
    g.add_argument("--seed", type=int, default=1, help="template provider only")
    g.add_argument("--max-attempts", type=int, default=3)
    g.add_argument("--no-critic", action="store_true")
    g.add_argument("--no-pending", action="store_true", help="ignore unpromoted proposals when planning")

    r = sub.add_parser("review", help="approve or reject proposed questions one by one")
    r.add_argument("proposal")
    r.add_argument("--reviewer", required=True, help="your name; recorded on every decision")

    rc = sub.add_parser("recheck", help="re-run the current verifier on an older proposal file")
    rc.add_argument("proposal")

    pr = sub.add_parser("promote", help="merge approved questions into the content pack (runs the validator)")
    pr.add_argument("proposal")

    sub.add_parser("status", help="show question coverage per skill and Bloom level")
    args = p.parse_args(argv)

    root = find_repo_root()
    load_dotenv(root / ".env")  # secrets live in hesabu/.env (git-ignored)
    try:
        if args.cmd == "status":
            print(status_table(root))
        elif args.cmd == "generate":
            state = run(make_llm(args), RunConfig(root=root, skill_id=args.skill, per_level=args.per_level,
                                                  max_attempts=args.max_attempts, use_critic=not args.no_critic,
                                                  include_pending=not args.no_pending))
            print("\n".join(state["log"]))
            if state.get("proposal_path"):
                print(f"\nNext: python -m hesabu_agents review {state['proposal_path']} --reviewer YOUR_NAME")
        elif args.cmd == "review":
            interactive_review(Path(args.proposal), args.reviewer)
            print("Saved. When done: python -m hesabu_agents promote", args.proposal)
        elif args.cmd == "recheck":
            s = recheck(Path(args.proposal), root)
            print(f"Rechecked {s['checked']} questions: {s['flagged']} with problems, "
                  f"{s['reopened']} approvals reopened, {s['warnings']} warnings.")
        elif args.cmd == "promote":
            ids = promote(Path(args.proposal), root)
            print(f"Promoted {len(ids)} questions: {', '.join(ids)}\nNow review the diff and commit.")
    except (LLMError, KeyError, ValueError, RuntimeError, FileNotFoundError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0
