# Bloom-validation spec — planned → live gate

## Purpose

Every planned Grade 4 Numbers skill must carry **exactly two validated
questions** mapped to its CAPS outcome code before its status can move from
`planned` to `live`. `validate_content.py` enforces this as a **pre-merge
gate**, not a post-approval review: a planned skill whose content does not
satisfy the gate is not allowed to merge, so it can never reach `live`.

The gate turns the Bloom/validation layer into an actual check instead of a
shape: an unvalidated skill stays `planned` forever, and a skill whose two
questions are missing or mis-mapped can't slip into production.

---

## Schema — skill entry in `packages/content_pack/assets/grade4/skills.json`

Each planned skill adds four fields to the existing entry:

```json
{
  "id": "g4.num.whole.order-round",
  "title": "Order and round numbers",
  "grade": 4,
  "strand": "Numbers",
  "subStrand": "Whole Numbers",
  "prerequisites": ["g4.num.whole.place-value"],
  "status": "planned",
  "kicdRef": "Gr4 Math 1.1 (d,e)",
  "outcome_code": "Gr4 Math 1.1 (d,e)",
  "bloom_verb": "order",
  "question_pair": ["g4num.order.round.q1", "g4num.order.round.q2"],
  "validated": false
}
```

| Field | Rule |
| --- | --- |
| `outcome_code` | Non-empty CAPS / KICD design reference (refer, never copy KICD text). Must be present and match a real sub-strand section. |
| `bloom_verb` | One of the Grade 4 Numbers verbs below (`count`, `compare`, `order`, `round`, `add`, `subtract`, `multiply`, `divide`). |
| `question_pair` | Array of **exactly two** question IDs from the grade-4 question pack. |
| `validated` | Boolean. Only `validate_content.py` may set it `true`. `validated: false` blocks the planned → live handoff, so the PR cannot pass. |

## Field-level rules

1. `outcome_code` must be a non-empty string and must reference a KICD Grade 4
   Numbers design section.
2. `bloom_verb` must be one of the verbs in the table below.
3. `question_pair` must contain exactly two IDs, both of which exist in the
   grade-4 question pack and map to this skill (`skillId` matches the skill's
   `id`).
4. `validated` is `false` by default and is flipped `true` **only** by the gate.
   Engineers never set it `true` by hand.

## Gate logic (`validate_content.py`)

Pre-merge. Runs over `skills.json` for every grade folder.

For each skill whose status is `planned`:

- exactly two questions must map to its `outcome_code` (i.e. the two entries in
  `question_pair` must both exist, both be owned by this skill, and both be at a
  core Bloom level);
- if any assertion fails, emit an `ERROR` and the gate exits non-zero, so the PR
  is blocked;
- if all planned skills pass, `validate_content.py` sets `validated: true` for
  every planned skill and exits zero.

A skill whose questions are incomplete **cannot** be marked `live`.

## Grade 4 Numbers — Bloom verbs table

Every planned skill must sit on one of these verbs. The two questions that map
to the skill's `outcome_code` verify the verb is being measured at the right
level.

| Bloom verb | Bloom level | Grade 4 Numbers outcome | Question template 1 | Question template 2 |
| --- | --- | --- | --- | --- |
| `count` | remember | Count groups of tens and hundreds | "How many dots are in this array?" | "A box holds 100 stickers. How many in 6 boxes?" |
| `compare` | understand | Compare numbers up to 10,000 | "Put `<`, `>` or `=` : 4,567 __ 4,657" | "Explain why 7,302 > 7,299." |
| `order` | analyze | Order numbers up to 10,000 | "Arrange smallest→largest: 3,412 / 3,142 / 3,421" | "Which does not belong? 1,200 / 1,020 / 1,002 / 1,202" |
| `round` | apply | Round to nearest 10 and 100 | "Round 4,567 to the nearest 10." | "Round 4,567 to the nearest 100." |
| `add` | apply | Addition with regrouping (up to 4 digits) | "Work out: 3,452 + 2,314" | "A school has 2,345 learners and admits 1,287. Total?" |
| `subtract` | apply | Subtraction with regrouping (up to 4 digits) | "Work out: 4,205 − 1,837" | "Harvested 5,000 kg, sold 2,786 kg. Left?" |
| `multiply` | apply | Multiplication (up to 2 × 2 digits) | "Work out: 24 × 13" | "A box holds 24 cans. How many in 13 boxes?" |
| `divide` | analyze | Division by a one-digit number | "Work out: 84 ÷ 6" | "Share 73 sweets among 5 children. How many each? Remainder?" |

## How a planned skill becomes `live`

1. Engineer writes `outcome_code`, `bloom_verb`, `question_pair` and two questions
   (each at a core Bloom level) in the grade-4 question pack.
2. PR is opened. Pre-merge gate: `validate_content.py` checks every planned
   skill's two-question pair against its `outcome_code`.
3. If the gate passes, `validated` flips to `true`; engineer then sets
   `status: "live"`.
4. Merge is only allowed once `validated` is `true` for every planned skill the
   PR introduces.

## Deviation log

- v1: gate requires exactly two questions per planned `outcome_code`; `validated`
  is the machine-readable proof; no hand-editing of `validated`.
