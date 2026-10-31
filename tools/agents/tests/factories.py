"""Hand-built, known-good questions for the newer check kinds, plus random variants for mutation tests."""
import random

from hesabu_agents.numwords import to_words
from hesabu_agents.safe_math import has_borrow, round_to

NAMES = ["Amina", "Brian", "Wanjiru", "Otieno", "Achieng"]


def fmt(n):
    return f"{n:,}"


def sub_word(rng):
    while True:
        a, b = rng.randint(2000, 9999), rng.randint(1000, 8999)
        if a > b and has_borrow(a, b):
            break
    return {"bloom": "apply", "type": "numericInput",
            "prompt": f"A shop had {fmt(a)} sacks of maize and sold {fmt(b)} sacks. How many sacks are left?",
            "answer": str(a - b), "hints": ["Subtract the sacks sold from the sacks the shop had."],
            "explanation": f"{fmt(a)} - {fmt(b)} = {fmt(a - b)} sacks.",
            "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}-{b}", "equals": a - b}}


def sub_plain(rng):
    while True:
        a, b = rng.randint(2000, 9999), rng.randint(1000, 8999)
        if a > b and not has_borrow(a, b):
            break
    return {"bloom": "remember", "type": "numericInput", "prompt": f"Work out: {fmt(a)} - {fmt(b)}",
            "answer": str(a - b), "hints": ["Subtract column by column from the ones."],
            "explanation": f"{fmt(a)} - {fmt(b)} = {fmt(a - b)}.",
            "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}-{b}", "equals": a - b}}


def mul_tens(rng):
    a, b = rng.randint(2, 99), rng.randint(1, 9) * 10
    return {"bloom": "remember", "type": "numericInput", "prompt": f"What is {a} x {b}?", "answer": str(a * b),
            "hints": [f"Multiply {a} by {b // 10}, then by 10."], "explanation": f"{a} x {b} = {a * b}.",
            "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}*{b}", "equals": a * b}}


def mul_two(rng):
    a, b = rng.randint(10, 99), rng.randint(10, 99)
    return {"bloom": "apply", "type": "numericInput",
            "prompt": f"A school has {a} rows of desks with {b} desks in each row. How many desks are there?",
            "answer": str(a * b), "hints": ["Multiply the number of rows by the desks in each row."],
            "explanation": f"{a} x {b} = {a * b} desks.",
            "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}*{b}", "equals": a * b}}


def mul_estimate(rng):
    a, b = rng.randint(11, 98), rng.randint(11, 98)
    ra, rb = int(round_to(a, 10)), int(round_to(b, 10))
    return {"bloom": "understand", "type": "numericInput",
            "prompt": f"Estimate {a} x {b} by rounding each number to the nearest ten first.",
            "answer": str(ra * rb), "hints": [f"{a} rounds to {ra} and {b} rounds to {rb}."],
            "explanation": f"{ra} x {rb} = {ra * rb}.",
            "check": {"kind": "expr", "givens": [a, b], "expr": f"round_to({a},10)*round_to({b},10)", "equals": ra * rb}}


def div_quotient(rng):
    d = rng.randint(2, 9)
    quotient = rng.randint(2, 99 // d)
    n = d * quotient
    return {"bloom": "remember", "type": "numericInput", "prompt": f"What is {n} divided by {d}?",
            "answer": str(quotient), "hints": [f"Think: {d} times what number makes {n}?"],
            "explanation": f"{n} / {d} = {quotient} because {d} x {quotient} = {n}.",
            "check": {"kind": "division", "dividend": n, "divisor": d, "ask": "quotient"}}


def div_remainder(rng):
    while True:
        d, n = rng.randint(2, 9), rng.randint(10, 99)
        if n % d:
            break
    return {"bloom": "apply", "type": "numericInput",
            "prompt": f"{n} mandazi are shared equally among {d} children. How many mandazi are left over?",
            "answer": str(n % d), "hints": [f"Find the biggest multiple of {d} that is not more than {n}."],
            "explanation": f"{n} / {d} = {n // d} remainder {n % d}, so {n % d} are left over.",
            "check": {"kind": "division", "dividend": n, "divisor": d, "ask": "remainder"}}


def div_qr(rng):
    while True:
        d, n = rng.randint(3, 9), rng.randint(20, 99)
        q, r = divmod(n, d)
        if r and q > 1:
            break
    wrong = [(q, r + 1 if r + 1 < d else r - 1), (q + 1, r), (q - 1, r)]
    names = ["answer_remainder_off_by_one", "quotient_rounded_up", "quotient_too_small"]
    return {"bloom": "understand", "type": "multipleChoice", "prompt": f"Divide {n} by {d}. Which answer is correct?",
            "choices": [{"text": f"{q} remainder {r}", "correct": True},
                        *[{"text": f"{a} remainder {b}", "misconception": m, "feedback": "Check by multiplying back."}
                          for (a, b), m in zip(wrong, names)]],
            "hints": [f"Multiply {d} by the quotient and add the remainder to check."],
            "explanation": f"{n} / {d} = {q} remainder {r} because {d} x {q} + {r} = {n}.",
            "check": {"kind": "division", "dividend": n, "divisor": d, "ask": "quotient_and_remainder"}}


def order_q(rng):
    nums = rng.sample(range(100, 1000), 4)
    asc = rng.random() < 0.5
    right = sorted(nums, reverse=not asc)
    wrong = set()
    while len(wrong) < 3:
        cand = rng.sample(nums, 4)
        if cand != right:
            wrong.add(tuple(cand))
    return {"bloom": "apply", "type": "multipleChoice",
            "prompt": f"Arrange {', '.join(map(str, nums))} from {'smallest to largest' if asc else 'largest to smallest'}.",
            "choices": [{"text": ", ".join(map(str, right)), "correct": True},
                        *[{"text": ", ".join(map(str, w)), "misconception": "compares_digits_wrongly",
                           "feedback": "Compare the hundreds first, then the tens."} for w in sorted(wrong)]],
            "hints": ["Compare the hundreds digits first."],
            "explanation": f"In order: {', '.join(map(str, right))}.",
            "check": {"kind": "order", "numbers": nums, "direction": "ascending" if asc else "descending"}}


def round_ten(rng):
    n = rng.randint(11, 999)
    r = int(round_to(n, 10))
    return {"bloom": "remember", "type": "numericInput", "prompt": f"Round {n} to the nearest ten.", "answer": str(r),
            "hints": ["Look at the ones digit: 5 or more rounds up."], "explanation": f"{n} rounds to {r}.",
            "check": {"kind": "expr", "givens": [n], "expr": f"round_to({n},10)", "equals": r}}


def words_to_digits(rng):
    n = rng.randint(21, 999)
    return {"bloom": "remember", "type": "numericInput", "prompt": f"Write {to_words(n)} in digits.", "answer": str(n),
            "hints": ["Hundreds first, then tens, then ones."], "explanation": f"{to_words(n)} is {n}.",
            "check": {"kind": "words", "number": n, "ask": "to_digits"}}


def digits_to_words(rng):
    n = rng.randint(101, 999)
    while n % 100 == 0 or n % 10 == 0:
        n = rng.randint(101, 999)
    off = [n + 10, n - 10, int(str(n)[::-1]) if int(str(n)[::-1]) != n else n + 1]
    return {"bloom": "understand", "type": "multipleChoice", "prompt": f"Which words show {n}?",
            "choices": [{"text": to_words(n), "correct": True},
                        *[{"text": to_words(o), "misconception": "reads_digits_wrongly", "feedback": "Read each place carefully."}
                          for o in off]],
            "hints": ["Say the hundreds, then the tens and ones."], "explanation": f"{n} is {to_words(n)}.",
            "check": {"kind": "words", "number": n, "ask": "to_words"}}


FACTORIES = {
    "g4.num.sub.regroup": [sub_plain, sub_word],
    "g4.num.mul.tens": [mul_tens],
    "g4.num.mul.two-digit": [mul_two, mul_estimate],
    "g4.num.div.one-digit": [div_quotient, div_remainder, div_qr],
    "g4.num.whole.order-round": [order_q, round_ten],
    "g4.num.whole.read-write": [words_to_digits, digits_to_words],
}


def samples(skill, n=40, seed=5):
    rng = random.Random(seed)
    for f in FACTORIES[skill]:
        for _ in range(n):
            yield f.__name__, f(rng)
