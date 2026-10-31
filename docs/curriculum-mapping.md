# Curriculum mapping

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


**97 skills mapped, 2 live.**


## Grade 4 (32 skills)


### Numbers

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Whole Numbers | Place value and total value (`g4.num.whole.place-value`) | **live** | Gr4 Math 1.1 (a,b) | none |
| Whole Numbers | Read and write numbers in words (`g4.num.whole.read-write`) | planned | Gr4 Math 1.1 (c) | `g4.num.whole.place-value` |
| Whole Numbers | Order and round numbers (`g4.num.whole.order-round`) | planned | Gr4 Math 1.1 (d,e) | `g4.num.whole.place-value` |
| Whole Numbers | Factors and multiples (`g4.num.whole.factors-multiples`) | planned | Gr4 Math 1.1 (f,g) | `g4.num.whole.place-value` |
| Whole Numbers | Even and odd numbers and patterns (`g4.num.whole.even-odd`) | planned | Gr4 Math 1.1 (h,i) | `g4.num.whole.place-value` |
| Whole Numbers | Roman numerals up to X (`g4.num.whole.roman`) | planned | Gr4 Math 1.1 (j) | none |
| Addition | Addition with regrouping (`g4.num.add.regroup`) | **live** | Gr4 Math 1.2 (a-d) | `g4.num.whole.place-value` |
| Subtraction | Subtraction with regrouping (`g4.num.sub.regroup`) | planned | Gr4 Math 1.3 (a-d) | `g4.num.add.regroup` |
| Multiplication | Multiply by multiples of 10 (`g4.num.mul.tens`) | planned | Gr4 Math 1.4 (a) | `g4.num.add.regroup` |
| Multiplication | Multiply two-digit numbers (`g4.num.mul.two-digit`) | planned | Gr4 Math 1.4 (b,c,d) | `g4.num.mul.tens` |
| Division | Divide by a one-digit number (`g4.num.div.one-digit`) | planned | Gr4 Math 1.5 (a,b) | `g4.num.mul.two-digit` |
| Fractions | Represent fractions (`g4.num.frac.represent`) | planned | Gr4 Math 1.6 (a,b,c) | `g4.num.div.one-digit` |
| Fractions | Improper and mixed fractions (`g4.num.frac.convert`) | planned | Gr4 Math 1.6 (d,e) | `g4.num.frac.represent` |
| Decimals | Tenths and hundredths (decimals) (`g4.num.dec.tenths-hundredths`) | planned | Gr4 Math 1.7 (a-d) | `g4.num.whole.place-value`, `g4.num.frac.represent` |
| Use of Letters | Letters and simple expressions (`g4.num.letters.expressions`) | planned | Gr4 Math 1.8 (a,b,c) | `g4.num.add.regroup` |

### Measurement

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Length | Length in centimetres and metres (`g4.meas.length.cm-m`) | planned | Gr4 Math 2.1 (a-d) | none |
| Length | Perimeter of plane figures (`g4.meas.length.perimeter`) | planned | Gr4 Math 2.1 (e) | `g4.meas.length.cm-m`, `g4.num.add.regroup` |
| Length | Operations with metres and centimetres (`g4.meas.length.operations`) | planned | Gr4 Math 2.1 (f-i) | `g4.meas.length.cm-m`, `g4.num.sub.regroup`, `g4.num.div.one-digit` |
| Area | Area of squares and rectangles (`g4.meas.area.rows-columns`) | planned | Gr4 Math 2.2 (a-d) | `g4.num.mul.two-digit` |
| Volume | Volume by piling cubes (`g4.meas.volume.piling`) | planned | Gr4 Math 2.3 (a-c) | `g4.num.add.regroup` |
| Capacity | Capacity in litres (`g4.meas.capacity.litres`) | planned | Gr4 Math 2.4 (a-d) | `g4.num.add.regroup` |
| Mass | Mass in kilograms (`g4.meas.mass.kilograms`) | planned | Gr4 Math 2.5 (a-e) | `g4.num.add.regroup` |
| Time | Telling time: a.m. and p.m. (`g4.meas.time.read-tell`) | planned | Gr4 Math 2.6 (a,b,f) | none |
| Time | Time units and durations (`g4.meas.time.convert-duration`) | planned | Gr4 Math 2.6 (c,d,e) | `g4.meas.time.read-tell`, `g4.num.sub.regroup` |
| Money | Shillings and cents (`g4.meas.money.shillings-cents`) | planned | Gr4 Math 2.7 (a) | `g4.num.add.regroup` |
| Money | Shopping lists and total cost (`g4.meas.money.shopping-list`) | planned | Gr4 Math 2.7 (b,c) | `g4.meas.money.shillings-cents`, `g4.num.add.regroup` |

### Geometry

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Position and Direction | Turns and direction (`g4.geo.position.turns`) | planned | Gr4 Math 3.1 (a-d) | none |
| Angles | Angles around us (`g4.geo.angles.identify`) | planned | Gr4 Math 3.2 (a,b,c) | `g4.geo.position.turns` |
| Plane Figures | Plane figures (`g4.geo.plane.identify-draw`) | planned | Gr4 Math 3.3 (a,b) | none |
| Plane Figures | Lines of symmetry and patterns (`g4.geo.plane.symmetry-patterns`) | planned | Gr4 Math 3.3 (c,d) | `g4.geo.plane.identify-draw` |
| Plane Figures | Properties of squares, rectangles and triangles (`g4.geo.plane.properties`) | planned | Gr4 Math 3.3 (e) | `g4.geo.plane.identify-draw` |

### Data Handling

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Data | Collect, record and read data in tables (`g4.data.tables`) | planned | Gr4 Math 4.1 (a-e) | none |

## Grade 5 (31 skills)


### Numbers

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Whole Numbers | Place value up to hundreds of thousands (`g5.num.whole.place-value`) | planned | Gr5 Math 1.1 (a,b) | `g4.num.whole.place-value` |
| Whole Numbers | Read, order and round bigger numbers (`g5.num.whole.read-order-round`) | planned | Gr5 Math 1.1 (c,d,e) | `g5.num.whole.place-value`, `g4.num.whole.read-write`, `g4.num.whole.order-round` |
| Whole Numbers | Divisibility tests for 2, 5 and 10 (`g5.num.whole.divisibility`) | planned | Gr5 Math 1.1 (f) | `g4.num.whole.factors-multiples` |
| Whole Numbers | Highest common factor (HCF/GCD) (`g5.num.whole.hcf-gcd`) | planned | Gr5 Math 1.1 (g) | `g4.num.whole.factors-multiples` |
| Whole Numbers | Least common multiple (LCM) (`g5.num.whole.lcm`) | planned | Gr5 Math 1.1 (h) | `g4.num.whole.factors-multiples` |
| Addition | Add up to 6-digit numbers (`g5.num.add.six-digit`) | planned | Gr5 Math 1.2 (a-d) | `g4.num.add.regroup`, `g5.num.whole.place-value` |
| Subtraction | Subtract up to 6-digit numbers (`g5.num.sub.six-digit`) | planned | Gr5 Math 1.3 (a-e) | `g4.num.sub.regroup`, `g5.num.add.six-digit` |
| Multiplication | Multiply 3-digit by 2-digit numbers (`g5.num.mul.three-by-two`) | planned | Gr5 Math 1.4 (a,b,c) | `g4.num.mul.two-digit` |
| Division | Divide 3-digit by 2-digit numbers (`g5.num.div.three-by-two`) | planned | Gr5 Math 1.5 (a,b,c) | `g4.num.div.one-digit`, `g5.num.mul.three-by-two` |
| Division | Combined operations (`g5.num.ops.combined`) | planned | Gr5 Math 1.5 (d) | `g5.num.sub.six-digit`, `g5.num.mul.three-by-two`, `g5.num.div.three-by-two` |
| Fractions | Equivalent fractions and simplifying (`g5.num.frac.equivalent-simplify`) | planned | Gr5 Math 1.6 (a) | `g4.num.frac.represent`, `g5.num.whole.hcf-gcd` |
| Fractions | Compare and order fractions (`g5.num.frac.compare-order`) | planned | Gr5 Math 1.6 (b,c) | `g5.num.frac.equivalent-simplify` |
| Fractions | Add and subtract fractions (`g5.num.frac.add-sub`) | planned | Gr5 Math 1.6 (d-g) | `g5.num.frac.equivalent-simplify` |
| Decimals | Decimals: place value and order (`g5.num.dec.thousandths`) | planned | Gr5 Math 1.7 (a,b) | `g4.num.dec.tenths-hundredths` |
| Decimals | Add and subtract decimals (`g5.num.dec.add-sub`) | planned | Gr5 Math 1.7 (c,d) | `g5.num.dec.thousandths`, `g4.num.add.regroup`, `g4.num.sub.regroup` |
| Simple Equations | Simple equations (`g5.num.equations.simple`) | planned | Gr5 Math 1.8 (a,b) | `g4.num.letters.expressions` |

### Measurement

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Length | Kilometres and metres (`g5.meas.length.km`) | planned | Gr5 Math 2.1 (a-d) | `g4.meas.length.cm-m` |
| Length | Operations with kilometres and metres (`g5.meas.length.operations`) | planned | Gr5 Math 2.1 (e-h) | `g5.meas.length.km`, `g5.num.mul.three-by-two`, `g5.num.div.three-by-two` |
| Area | Area in square centimetres (`g5.meas.area.cm2`) | planned | Gr5 Math 2.2 (a,b) | `g4.meas.area.rows-columns` |
| Volume | Volume of cubes and cuboids (`g5.meas.volume.cm3`) | planned | Gr5 Math 2.3 (a-e) | `g4.meas.volume.piling`, `g5.meas.area.cm2` |
| Capacity | Millilitres and litres (`g5.meas.capacity.millilitres`) | planned | Gr5 Math 2.4 (a-e) | `g4.meas.capacity.litres` |
| Capacity | Operations with litres and millilitres (`g5.meas.capacity.operations`) | planned | Gr5 Math 2.4 (f-i) | `g5.meas.capacity.millilitres`, `g5.num.mul.three-by-two`, `g5.num.div.three-by-two` |
| Mass | Grams and kilograms (`g5.meas.mass.grams`) | planned | Gr5 Math 2.5 (a-e) | `g4.meas.mass.kilograms` |
| Mass | Operations with grams and kilograms (`g5.meas.mass.operations`) | planned | Gr5 Math 2.5 (f-j) | `g5.meas.mass.grams`, `g5.num.mul.three-by-two`, `g5.num.div.three-by-two` |
| Time | Seconds and minutes (`g5.meas.time.seconds`) | planned | Gr5 Math 2.6 (a,b,c,h) | `g4.meas.time.convert-duration` |
| Time | Operations with minutes and seconds (`g5.meas.time.operations`) | planned | Gr5 Math 2.6 (d-g) | `g5.meas.time.seconds`, `g5.num.mul.three-by-two`, `g5.num.div.three-by-two` |
| Money | Budgets, tax and banks (`g5.meas.money.budget-tax-banks`) | planned | Gr5 Math 2.7 (a-f) | `g4.meas.money.shopping-list` |

### Geometry

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Lines | Types of lines (`g5.geo.lines`) | planned | Gr5 Math 3.1 (a-f) | `g4.geo.plane.identify-draw` |
| Angles | Measuring angles in degrees (`g5.geo.angles.protractor`) | planned | Gr5 Math 3.2 (a-e) | `g4.geo.angles.identify` |
| 3-D Objects | 3-D objects and their shapes (`g5.geo.3d.describe`) | planned | Gr5 Math 3.3 (a,b) | `g4.geo.plane.identify-draw` |

### Data Handling

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Data Representation | Tally marks and frequency tables (`g5.data.frequency-tables`) | planned | Gr5 Math 4.1 (a-e) | `g4.data.tables` |

## Grade 6 (34 skills)


### Numbers

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Whole Numbers | Place value up to millions (`g6.num.whole.place-value-millions`) | planned | Gr6 Math 1.1 (a,b) | `g5.num.whole.place-value` |
| Whole Numbers | Read, order and round numbers up to 100,000 (`g6.num.whole.read-order-round`) | planned | Gr6 Math 1.1 (c,d,e) | `g6.num.whole.place-value-millions`, `g5.num.whole.read-order-round` |
| Whole Numbers | Squares and square roots (`g6.num.whole.squares-roots`) | planned | Gr6 Math 1.1 (f,g) | `g5.num.mul.three-by-two` |
| Multiplication | Multiply 4-digit by 2-digit numbers (`g6.num.mul.four-by-two`) | planned | Gr6 Math 1.2 (a,b,c) | `g5.num.mul.three-by-two` |
| Division | Divide up to 4-digit by 3-digit numbers (`g6.num.div.four-by-three`) | planned | Gr6 Math 1.3 (a,b) | `g5.num.div.three-by-two`, `g6.num.mul.four-by-two` |
| Division | Combined operations up to 3-digit numbers (`g6.num.ops.combined`) | planned | Gr6 Math 1.3 (c) | `g5.num.ops.combined`, `g6.num.div.four-by-three` |
| Fractions | Add and subtract fractions using LCM (`g6.num.frac.add-sub-lcm`) | planned | Gr6 Math 1.4 (a,b) | `g5.num.frac.add-sub`, `g5.num.whole.lcm` |
| Fractions | Add and subtract mixed numbers (`g6.num.frac.mixed`) | planned | Gr6 Math 1.4 (c,d) | `g6.num.frac.add-sub-lcm`, `g4.num.frac.convert` |
| Fractions | Reciprocals and squares of fractions (`g6.num.frac.reciprocal-squares`) | planned | Gr6 Math 1.4 (e,f) | `g6.num.frac.add-sub-lcm`, `g6.num.whole.squares-roots` |
| Fractions | Fractions and percentages (`g6.num.frac.percent`) | planned | Gr6 Math 1.4 (g,h) | `g5.num.frac.equivalent-simplify` |
| Decimals | Decimals: ten-thousandths and rounding (`g6.num.dec.ten-thousandths-round`) | planned | Gr6 Math 1.5 (a,b) | `g5.num.dec.thousandths` |
| Decimals | Decimals, fractions and percentages (`g6.num.dec.convert`) | planned | Gr6 Math 1.5 (c,d) | `g6.num.dec.ten-thousandths-round`, `g6.num.frac.percent` |
| Decimals | Add and subtract decimals (4 places) (`g6.num.dec.add-sub`) | planned | Gr6 Math 1.5 (e,f) | `g5.num.dec.add-sub`, `g6.num.dec.ten-thousandths-round` |
| Inequalities | Simple inequalities (`g6.num.inequalities`) | planned | Gr6 Math 1.6 (a,b,c) | `g5.num.equations.simple` |

### Measurement

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Length | Millimetres and centimetres (`g6.meas.length.mm`) | planned | Gr6 Math 2.1 (a,b,c) | `g4.meas.length.cm-m` |
| Length | Operations with centimetres and millimetres (`g6.meas.length.operations`) | planned | Gr6 Math 2.1 (d-g) | `g6.meas.length.mm`, `g6.num.mul.four-by-two`, `g6.num.div.four-by-three` |
| Length | Circumference and diameter (`g6.meas.length.circumference`) | planned | Gr6 Math 2.1 (h,i) | `g6.meas.length.mm`, `g5.num.dec.thousandths` |
| Area | Area of triangles and combined shapes (`g6.meas.area.triangles`) | planned | Gr6 Math 2.2 (a,b) | `g5.meas.area.cm2` |
| Area | Estimate the area of circles (`g6.meas.area.circles-estimate`) | planned | Gr6 Math 2.2 (c) | `g5.meas.area.cm2` |
| Capacity | Cubic centimetres, millilitres and litres (`g6.meas.capacity.cm3-ml-l`) | planned | Gr6 Math 2.3 (a-c) | `g5.meas.capacity.millilitres`, `g5.meas.volume.cm3` |
| Mass | Tonnes and kilograms (`g6.meas.mass.tonnes`) | planned | Gr6 Math 2.4 (a-e) | `g5.meas.mass.grams` |
| Mass | Operations with tonnes and kilograms (`g6.meas.mass.operations`) | planned | Gr6 Math 2.4 (f-i) | `g6.meas.mass.tonnes`, `g6.num.mul.four-by-two`, `g6.num.div.four-by-three` |
| Time | 12-hour and 24-hour clocks (`g6.meas.time.am-pm-24h`) | planned | Gr6 Math 2.5 (a-d) | `g4.meas.time.read-tell` |
| Time | Travel timetables (`g6.meas.time.timetables`) | planned | Gr6 Math 2.5 (e) | `g6.meas.time.am-pm-24h`, `g5.meas.time.operations` |
| Money | Simple budgets (`g6.meas.money.budget`) | planned | Gr6 Math 2.6 (a) | `g5.meas.money.budget-tax-banks` |
| Money | Prices, profit and loss (`g6.meas.money.profit-loss`) | planned | Gr6 Math 2.6 (b,c,d) | `g6.meas.money.budget`, `g5.num.sub.six-digit` |
| Money | Types of taxes (`g6.meas.money.taxes`) | planned | Gr6 Math 2.6 (e) | `g5.meas.money.budget-tax-banks` |

### Geometry

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Lines | Constructing lines (`g6.geo.lines.construct`) | planned | Gr6 Math 3.1 (a,b,c) | `g5.geo.lines` |
| Angles | Angles on a straight line (`g6.geo.angles.straight-line`) | planned | Gr6 Math 3.2 (a,b,c) | `g5.geo.angles.protractor` |
| Angles | Angle sums in triangles and rectangles (`g6.geo.angles.sum`) | planned | Gr6 Math 3.2 (d) | `g6.geo.angles.straight-line` |
| Angles | Construct and measure triangles (`g6.geo.triangles.construct`) | planned | Gr6 Math 3.2 (e,f) | `g6.geo.lines.construct`, `g6.geo.angles.sum` |
| 3-D Objects | Faces, edges, vertices and nets (`g6.geo.3d.faces-edges`) | planned | Gr6 Math 3.3 (a,b,c) | `g5.geo.3d.describe` |

### Data Handling

| Sub-strand | Skill | Status | KICD | Prerequisites |
|---|---|---|---|---|
| Bar Graphs | Frequency tables, pictographs and piling (`g6.data.pictographs-frequency`) | planned | Gr6 Math 4.1 (a,b,c) | `g5.data.frequency-tables` |
| Bar Graphs | Bar graphs (`g6.data.bar-graphs`) | planned | Gr6 Math 4.1 (d,e) | `g6.data.pictographs-frequency` |
