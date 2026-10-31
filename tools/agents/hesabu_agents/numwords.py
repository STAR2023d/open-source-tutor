"""Number words, British style ("four hundred and twenty-six"). Used to verify
reading and writing numbers in words, up to 999,999."""
from __future__ import annotations

import re

ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
        "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty", 6: "sixty", 7: "seventy", 8: "eighty", 9: "ninety"}
_WORD_VALUE = {w: i for i, w in enumerate(ONES)} | {w: t * 10 for t, w in TENS.items()}


def to_words(n: int) -> str:
    if not 0 <= n <= 999_999:
        raise ValueError("supported range is 0 to 999,999")
    if n < 20:
        return ONES[n]
    if n < 100:
        return TENS[n // 10] + (f"-{ONES[n % 10]}" if n % 10 else "")
    if n < 1000:
        return f"{ONES[n // 100]} hundred" + (f" and {to_words(n % 100)}" if n % 100 else "")
    rest = n % 1000
    head = f"{to_words(n // 1000)} thousand"
    if not rest:
        return head
    return head + (" and " if rest < 100 else " ") + to_words(rest)


def from_words(text: str) -> int | None:
    """Parse number words; returns None if the text is not a valid number in words."""
    raw = re.sub(r"[-,]", " ", (text or "").lower()).split()
    if raw and (raw[0] == "and" or raw[-1] == "and"):
        return None
    s = [w for w in raw if w != "and"]
    if not s:
        return None
    total = current = 0
    for w in s:
        if w in _WORD_VALUE:
            current += _WORD_VALUE[w]
        elif w == "hundred" and current:
            current *= 100
        elif w == "thousand" and current:
            total, current = total + current * 1000, 0
        else:
            return None
    value = total + current
    # reject sloppy forms such as "twenty twenty" by requiring the canonical spelling to round-trip
    if 0 <= value <= 999_999 and re.sub(r"[-,]", " ", to_words(value)).replace(" and ", " ").split() == s:
        return value
    return None
