import pytest
from fractions import Fraction

from hesabu_agents.safe_math import UnsafeExpression, has_carry, ints_in, parse_number, round_to, safe_eval


def test_basic_and_exact():
    assert safe_eval("3648+2975") == 6623
    assert safe_eval("10/4") == Fraction(5, 2)
    assert safe_eval("round_to(2758,10)+round_to(1436,10)") == 4200
    assert safe_eval("max(9876,10234)") == 10234
    assert round_to(2755, 10) == 2760  # half rounds up


@pytest.mark.parametrize("bad", [
    "__import__('os').system('ls')", "open('x')", "2**9999", "1/0", "[1,2]", "a+1",
    "'abc'", "True+1", "(lambda: 1)()", "round_to(5,0)", "x" * 200,
])
def test_rejects_anything_unsafe(bad):
    with pytest.raises(UnsafeExpression):
        safe_eval(bad)


def test_helpers():
    assert ints_in("3,648 shillings and 2,975, then 12") == {3648, 2975, 12}
    assert parse_number("1,234") == 1234 and parse_number("abc") is None and parse_number(True) is None
    assert has_carry(3648, 2975) and not has_carry(3452, 2314)
