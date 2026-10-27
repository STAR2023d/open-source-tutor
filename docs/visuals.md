# Teaching pictures (visuals)

Why: children learn new maths best by moving from **Concrete** (real objects) to **Pictorial**
(drawings) to **Abstract** (symbols). On a screen we cannot hand out beads, so the pictures carry the
pictorial step, and the same pictures can come back as hints when a learner is stuck.

A question may have an optional `visual` field. `showWith` controls timing:
- `"prompt"` (default): shown with the question (good for word problems).
- `"hint"`: shown when the learner asks for their first hint, and after they answer. The question
  must have at least one hint. Using the hint means the answer does not count as "clean" mastery evidence.

| type | Use it for | Parameters |
|---|---|---|
| `placeValueChart` | place value, total value, reading and writing numbers | `value` (0-99999), `mode` (`digits`/`counters`), `showLabels`, `showValues`, `highlight` (e.g. `["thousands"]`), `minPlaces` |
| `columnAddition` | regrouping | `a`, `b`, `showCarries`, `showResult` |
| `barModel` | word problems (part-whole) | `parts` [{label, value}], `total`, `totalLabel` |
| `numberLine` | ordering, rounding, estimation | `min`, `max`, `step`, `labelEvery`, `marks` [{value, label}] |
| `fractionBar` | fractions, improper and mixed | `numerator`, `denominator` (1-12), `style` (`bar`/`group`), `showLabel` |
| `arrayGrid` | multiplication, area | `rows`, `cols` (1-12), `showCounts` |

Design rule: a picture must never print the answer. If the answer would show, use `showWith: "hint"`
and hide the revealing part (for example `showResult: false`, or no `highlight`).

Add a new picture type in four places: the widget in `lib/visuals/`, a case in `visual_factory.dart`,
an entry in `VISUALS` in `tools/validate_content.py`, and a card in the picture gallery
(Settings -> Picture gallery) with a widget test.
