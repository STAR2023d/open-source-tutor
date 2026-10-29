# Content pipeline: why it is built this way

**Problem.** Learners need hundreds of good questions. Writing them by hand does not scale, and a model that
writes a wrong answer key harms a child's learning.

**Principle.** The model drafts; code verifies; a human decides.

1. **Planner** (code) compares existing questions with the target of 6 per Bloom level and decides what to ask for.
2. **Generator** (LLM) drafts questions in our JSON schema, each with a machine-checkable `check`.
3. **Verifier** (code, no LLM) recomputes answers with exact arithmetic and enforces range, regrouping, picture
   and duplicate rules. Failures go back to the generator with the exact problems listed (up to 3 rounds).
4. **Critic** (LLM) judges what code cannot: clarity, reading level, cultural fit, distractor realism. It can only reject.
5. **Human review** (`review`): the teacher sees the question, the answer, the misconceptions and the code checks.
   Approvals are recorded with the reviewer's name and are required for promotion.
6. **Promote** (`promote`): merges approved questions, strips pipeline fields, runs the content validator and
   rolls everything back if it fails.

**Why LangGraph.** The loop (verify, revise, verify) and the human gate are a graph, not a script. LangGraph makes
the routing explicit and testable, and lets us swap the model, add nodes (for example a Swahili translator) or
add persistence and human-in-the-loop interrupts later.

**What it cannot do (yet).** It cannot judge whether a question is good pedagogy, only that it is correct and well formed.
That is the reviewer's job. Extra `check` kinds are needed for fractions, decimals, geometry and measurement.
