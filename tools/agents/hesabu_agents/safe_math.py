"""Tiny, safe arithmetic evaluator.

Why: the generator (an LLM) must give every question a machine-checkable
`check.expr`. We evaluate it with this evaluator, never with eval(), so a
model can neither do harm nor "grade its own homework" with a wrong answer.
Exact arithmetic (Fraction) avoids floating-point surprises.
"""
from __future__ import annotations

import ast
import math
import operator
import re
from fractions import Fraction


class UnsafeExpression(ValueError):
    """Raised for anything that is not plain arithmetic."""


MAX_ABS = Fraction(10**12)
_BIN = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
}


def round_to(x, base) -> Fraction:
    """Round half up to the nearest multiple of base (school rounding)."""
    x, base = Fraction(x), Fraction(base)
    if base <= 0:
        raise UnsafeExpression("round_to base must be positive")
    return Fraction(math.floor(x / base + Fraction(1, 2))) * base


_FUNCS = {"round_to": round_to, "max": max, "min": min}


def safe_eval(expr: str) -> Fraction:
    if not isinstance(expr, str) or len(expr) > 160:
        raise UnsafeExpression("expression missing or too long")
    try:
        tree = ast.parse(expr.strip(), mode="eval")
    except SyntaxError as e:
        raise UnsafeExpression(f"syntax error: {e.msg}") from e

    def ev(n) -> Fraction:
        if isinstance(n, ast.Expression):
            return ev(n.body)
        if isinstance(n, ast.Constant):
            v = n.value
            if isinstance(v, bool) or not isinstance(v, (int, float)):
                raise UnsafeExpression("only numbers are allowed")
            return Fraction(str(v))
        if isinstance(n, ast.UnaryOp) and isinstance(n.op, ast.USub):
            return -ev(n.operand)
        if isinstance(n, ast.BinOp) and type(n.op) in _BIN:
            a, b = ev(n.left), ev(n.right)
            if isinstance(n.op, (ast.Div, ast.FloorDiv, ast.Mod)) and b == 0:
                raise UnsafeExpression("division by zero")
            r = Fraction(_BIN[type(n.op)](a, b))
            if abs(r) > MAX_ABS:
                raise UnsafeExpression("number too large")
            return r
        if (
            isinstance(n, ast.Call)
            and isinstance(n.func, ast.Name)
            and n.func.id in _FUNCS
            and not n.keywords
            and 1 <= len(n.args) <= 4
        ):
            return Fraction(_FUNCS[n.func.id](*[ev(a) for a in n.args]))
        raise UnsafeExpression(f"not allowed: {type(n).__name__}")

    return ev(tree)


_NUM = re.compile(r"\d+(?:,\d{3})*")


def ints_in(text: str) -> set[int]:
    """All whole numbers in a text, reading '2,975' as 2975."""
    return {int(m.replace(",", "")) for m in _NUM.findall(text or "")}


def int_list_in(text: str) -> list[int]:
    """Like ints_in but keeps repeats, so [9, 9] must appear twice in a prompt."""
    return [int(m.replace(",", "")) for m in _NUM.findall(text or "")]


def parse_number(text) -> Fraction | None:
    if isinstance(text, bool):
        return None
    if isinstance(text, (int, float)):
        return Fraction(str(text))
    try:
        return Fraction(str(text).replace(",", "").replace(" ", ""))
    except (ValueError, ZeroDivisionError):
        return None


def has_carry(a: int, b: int) -> bool:
    """True if adding a + b column by column needs regrouping."""
    carry = 0
    while a or b or carry:
        s = a % 10 + b % 10 + carry
        if s >= 10:
            return True
        carry = 0
        a //= 10
        b //= 10
    return False
