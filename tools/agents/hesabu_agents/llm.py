"""LLM providers. All are plain HTTP (urllib) so there is nothing extra to install.

- TemplateLLM: offline, deterministic, no model. Used for tests and for trying the pipeline.
- OpenAICompatibleLLM: any /chat/completions server (Ollama's /v1, Groq, OpenRouter, ...).
- GeminiLLM: Google's generateContent REST API.
Only TemplateLLM is covered by automated tests; the two network providers are untested here.
"""
from __future__ import annotations

import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.request
from typing import Protocol

from .prompts import PROMPT_VERSION  # noqa: F401  (re-exported for metadata)
from .safe_math import round_to


class LLMClient(Protocol):
    name: str

    def complete(self, system: str, user: str) -> str: ...


class LLMError(RuntimeError):
    pass


def extract_json(text: str):
    """Pull the first JSON object out of a model reply (handles ``` fences)."""
    text = re.sub(r"```(?:json)?", "", text or "")
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end <= start:
        raise LLMError("no JSON object in the model reply")
    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError as e:
        raise LLMError(f"invalid JSON from model: {e}") from e


RETRY_STATUS = {429, 500, 502, 503, 504}
RETRY_DELAYS = (3, 8, 20, 45)  # seconds; busy free-tier models usually recover quickly


def _retry_after(err: urllib.error.HTTPError) -> int | None:
    value = err.headers.get("Retry-After") if err.headers else None
    return int(value) if value and str(value).isdigit() else None


def _post(url: str, payload: dict, headers: dict, timeout: int = 120, retries: int = 4) -> dict:
    """POST JSON, retrying busy/overloaded responses (429, 5xx) and network blips with backoff."""
    req_headers = {"Content-Type": "application/json", **headers}
    body = json.dumps(payload).encode()
    for attempt in range(retries + 1):
        try:
            req = urllib.request.Request(url, data=body, headers=req_headers)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:300]
            if e.code in RETRY_STATUS and attempt < retries:
                wait = _retry_after(e) or RETRY_DELAYS[min(attempt, len(RETRY_DELAYS) - 1)]
                print(f"  model busy (HTTP {e.code}); retrying in {wait}s ({attempt + 1}/{retries})", file=sys.stderr)
                time.sleep(wait)
                continue
            raise LLMError(f"HTTP {e.code}: {detail}") from e
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < retries:
                wait = RETRY_DELAYS[min(attempt, len(RETRY_DELAYS) - 1)]
                print(f"  network problem ({e}); retrying in {wait}s ({attempt + 1}/{retries})", file=sys.stderr)
                time.sleep(wait)
                continue
            raise LLMError(f"network error: {e}") from e
    raise LLMError("unreachable")


class OpenAICompatibleLLM:
    def __init__(self, base_url: str, model: str, api_key: str | None = None, temperature: float = 0.7):
        self.base_url, self.model, self.temperature = base_url.rstrip("/"), model, temperature
        self.api_key = api_key or os.environ.get("HESABU_API_KEY", "")
        self.name = f"openai-compatible:{model}"

    def complete(self, system: str, user: str) -> str:
        headers = {"Authorization": f"Bearer {self.api_key}"} if self.api_key else {}
        data = _post(
            f"{self.base_url}/chat/completions",
            {
                "model": self.model,
                "temperature": self.temperature,
                "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            },
            headers,
        )
        try:
            return data["choices"][0]["message"]["content"]
        except (KeyError, IndexError) as e:
            raise LLMError(f"unexpected response shape: {str(data)[:200]}") from e


class GeminiLLM:
    def __init__(self, model: str, api_key: str | None = None, temperature: float = 0.7):
        self.model, self.temperature = model, temperature
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY", "")
        if not self.api_key:
            raise LLMError("GEMINI_API_KEY not found. Add a line GEMINI_API_KEY=your_key to hesabu/.env (it is git-ignored), or export it in this terminal.")
        self.name = f"gemini:{model}"

    def complete(self, system: str, user: str) -> str:
        data = _post(
            f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent",
            {
                "systemInstruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": [{"text": user}]}],
                "generationConfig": {"temperature": self.temperature, "responseMimeType": "application/json"},
            },
            {"x-goog-api-key": self.api_key},
        )
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError) as e:
            raise LLMError(f"unexpected response shape: {str(data)[:200]}") from e


# ====================================================================== offline
def fmt(n: int) -> str:
    return f"{n:,}"


NAMES = ["Amina", "Brian", "Wanjiru", "Otieno", "Achieng", "Kamau", "Zawadi", "Juma"]
PLACE_TITLE = {"ones": "Ones", "tens": "Tens", "hundreds": "Hundreds", "thousands": "Thousands", "ten thousands": "Ten thousands"}
PLACE_NAMES = ["ones", "tens", "hundreds", "thousands", "ten thousands"]


def _carry_cols(a: int, b: int) -> int:
    carry = n = 0
    while a or b or carry:
        s = a % 10 + b % 10 + carry
        carry = s // 10
        n += 1 if carry else 0
        a //= 10
        b //= 10
    return n


def _forgot_carries(a: int, b: int) -> int:
    """Column sums written without adding the regrouped digits (a classic error)."""
    da, db = str(a).zfill(5), str(b).zfill(5)
    out = [(int(x) + int(y)) % 10 for x, y in zip(da, db)]
    lead = 1 if (int(da[0]) + int(db[0])) >= 10 else 0
    return int(str(lead) + "".join(map(str, out))) if lead else int("".join(map(str, out)))


class TemplateLLM:
    """Offline question generator for the two live Grade 4 skills.

    It exists so the whole pipeline can run, be tested in CI and be demonstrated
    without any model or network. Real quality and variety come from a real LLM.
    `sabotage_first=True` makes the very first question wrong on purpose so tests
    can prove the verifier rejects it and the revise loop repairs it.
    """

    def __init__(self, seed: int = 1, sabotage_first: bool = False):
        self.rng = random.Random(seed)
        self.sabotage_first = sabotage_first
        self._sabotaged = False
        self.name = f"template-offline(seed={seed})"

    # ---- protocol
    def complete(self, system: str, user: str) -> str:
        m = re.search(r"TASK_JSON: (\{.*\})", user)
        if not m:
            raise LLMError("TemplateLLM needs a TASK_JSON line")
        t = json.loads(m.group(1))
        if t["task"] == "generate":
            qs = [self._build(t["skill_id"], t["level"]) for _ in range(t["count"])]
            if self.sabotage_first and not self._sabotaged and qs:
                self._sabotaged = True
                chk = qs[0]["check"]
                if "equals" in chk:
                    chk["equals"] += 1
                else:
                    chk["digit"] = (chk["digit"] + 1) % 10
            return json.dumps({"questions": qs})
        if t["task"] == "revise":
            return json.dumps({"questions": [self._build(t["skill_id"], t["level"])]})
        if t["task"] == "critique":
            return json.dumps({"reviews": [{"id": i, "ok": True, "issues": []} for i in t["ids"]]})
        raise LLMError(f"unknown task {t['task']}")

    # ---- builders
    def _build(self, skill_id: str, level: str) -> dict:
        table = {
            "g4.num.add.regroup": {
                "remember": self._add_plain, "understand": self._add_estimate,
                "apply": self._add_word, "analyze": self._add_analyze,
            },
            "g4.num.whole.place-value": {
                "remember": self._pv_remember, "understand": self._pv_total,
                "apply": self._pv_build, "analyze": self._pv_analyze,
            },
        }
        try:
            builders = table[skill_id][level]
        except KeyError as e:
            raise LLMError(f"TemplateLLM has no template for {skill_id} / {level}") from e
        return builders()

    def _digits_unique(self, n_digits: int) -> int:
        digs = self.rng.sample(range(10), n_digits)
        if digs[0] == 0:
            digs[0], digs[1] = digs[1], digs[0]
        return int("".join(map(str, digs)))

    # -- addition
    def _add_plain(self):
        while True:
            a = self.rng.randint(1000, 8999)
            b = self.rng.randint(1000, 8999)
            if not _carry_cols(a, b) and a + b <= 9999:
                break
        return {"bloom": "remember", "type": "numericInput", "prompt": f"Work out: {fmt(a)} + {fmt(b)}",
                "answer": str(a + b), "hints": ["Add the ones first, then the tens, hundreds and thousands."],
                "explanation": f"Add column by column: {fmt(a)} + {fmt(b)} = {fmt(a + b)}. No regrouping is needed.",
                "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}+{b}", "equals": a + b}}

    def _add_estimate(self):
        a, b = self.rng.randint(1100, 4900), self.rng.randint(1100, 4900)
        ra, rb = int(round_to(a, 10)), int(round_to(b, 10))
        return {"bloom": "understand", "type": "numericInput",
                "prompt": f"Estimate {fmt(a)} + {fmt(b)} by rounding each number to the nearest ten first. What is your estimate?",
                "answer": str(ra + rb), "hints": [f"{fmt(a)} rounds to {fmt(ra)}.", f"{fmt(b)} rounds to {fmt(rb)}."],
                "explanation": f"{fmt(ra)} + {fmt(rb)} = {fmt(ra + rb)}."
                + ("" if ra + rb == a + b else f" The exact answer is {fmt(a + b)}, so the estimate is close."),
                "check": {"kind": "expr", "givens": [a, b], "expr": f"round_to({a},10)+round_to({b},10)", "equals": ra + rb}}

    def _add_word(self):
        while True:
            a, b = self.rng.randint(1500, 6000), self.rng.randint(1500, 3900)
            if _carry_cols(a, b) and a + b <= 9999:
                break
        prompt = self.rng.choice([
            f"A shop earned {fmt(a)} shillings on Monday and {fmt(b)} shillings on Tuesday. How much did it earn altogether?",
            f"Wanjiru has {fmt(a)} trees on her farm and plants {fmt(b)} more. How many trees does she have now?",
            f"A school library has {fmt(a)} books and receives {fmt(b)} new books. How many books does it have now?",
            f"A matatu company carried {fmt(a)} passengers last week and {fmt(b)} this week. How many passengers is that in all?",
        ])
        return {"bloom": "apply", "type": "numericInput", "prompt": prompt, "answer": str(a + b),
                "hints": ["Add the two numbers. Start with the ones.", "When a column adds to 10 or more, regroup."],
                "explanation": f"{fmt(a)} + {fmt(b)} = {fmt(a + b)}.",
                "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}+{b}", "equals": a + b}}

    def _add_analyze(self):
        if self.rng.random() < 0.5:
            return self._add_peter()
        return self._add_compare()

    def _add_peter(self):
        while True:
            a, b = self.rng.randint(1500, 5000), self.rng.randint(1500, 4900)
            w = _forgot_carries(a, b)
            if _carry_cols(a, b) >= 2 and a + b <= 9999 and w != a + b:
                break
        s, who = a + b, self.rng.choice(NAMES)
        return {"bloom": "analyze", "type": "multipleChoice",
                "prompt": f"{who} says {fmt(a)} + {fmt(b)} = {fmt(w)}. The correct answer is {fmt(s)}. What mistake did {who} make?",
                "choices": [
                    {"text": "They wrote the regrouped digits but forgot to add them into the next column.", "correct": True},
                    {"text": "They added the ones column wrongly.", "misconception": "wrong_diagnosis_ones",
                     "feedback": f"Look again: the ones digit {w % 10} is right."},
                    {"text": "They should have subtracted.", "misconception": "wrong_operation",
                     "feedback": "The problem says add."},
                    {"text": "Nothing. Their answer is correct.", "misconception": "accepts_wrong_answer",
                     "feedback": "Estimate first: the answer should be close to the correct one."}],
                "hints": ["Estimate first: is the answer close to the correct one?", "Check each column and the regrouped digit."],
                "explanation": f"{fmt(a)} + {fmt(b)} = {fmt(s)}. {who} forgot to add each regrouped digit into the next column, so the answer came out too small.",
                "visual": {"type": "columnAddition", "a": a, "b": b, "showCarries": True, "showResult": True, "showWith": "hint"},
                "check": {"kind": "expr", "givens": [a, b], "expr": f"{a}+{b}", "equals": s}}

    def _add_compare(self):
        a, b = self.rng.randint(5000, 6000), self.rng.randint(100, 500)
        c, d = self.rng.randint(2000, 3000), self.rng.randint(4800, 5600)
        s1, s2 = a + b, c + d
        big = max(s1, s2)
        t1, t2 = f"{fmt(a)} + {fmt(b)}", f"{fmt(c)} + {fmt(d)}"
        right, other = (t2, t1)
        return {"bloom": "analyze", "type": "multipleChoice",
                "prompt": f"Which sum is greater: {t1} or {t2}?",
                "choices": [
                    {"text": right, "correct": True},
                    {"text": other, "misconception": "bigger_first_number_wins",
                     "feedback": "The first number is bigger, but the second number is much smaller. Add to check."},
                    {"text": "They are equal.", "misconception": "assumes_equal",
                     "feedback": "Estimate each sum by rounding. They are not close to equal."},
                    {"text": "You cannot tell without using a calculator.", "misconception": "avoids_estimation",
                     "feedback": "Rounding the numbers lets you compare without a calculator."}],
                "hints": ["Round each number, then add the rounded numbers."],
                "explanation": f"{t1} = {fmt(s1)} and {t2} = {fmt(s2)}. The greater sum is {fmt(big)}.",
                "check": {"kind": "expr", "givens": [a, b, c, d], "expr": f"max({a}+{b},{c}+{d})", "equals": big}}

    # -- place value
    def _pv_remember(self):
        if self.rng.random() < 0.5:
            return self._pv_place_name()
        return self._pv_which_number()

    def _pv_place_name(self):
        n = self._digits_unique(self.rng.choice([4, 5]))
        p = self.rng.randrange(0, len(str(n)))
        d, place = int(str(n)[len(str(n)) - 1 - p]), PLACE_NAMES[p]
        near = [q for q in (p - 1, p + 1, p + 2, p - 2) if 0 <= q < len(str(n))][:2]
        wrong = [{"text": PLACE_TITLE[PLACE_NAMES[q]], "misconception": "off_by_one_place",
                  "feedback": f"Count the places from the right: the {d} is not in the {PLACE_NAMES[q]} place."} for q in near]
        wrong.append({"text": fmt(d * 10 ** p), "misconception": "confuses_place_and_total_value",
                      "feedback": f"{fmt(d * 10 ** p)} is the total value. The place value is the NAME of the place."})
        while len(wrong) < 3:
            q = self.rng.choice([i for i in range(len(str(n))) if i != p and PLACE_TITLE[PLACE_NAMES[i]] not in {w['text'] for w in wrong}])
            wrong.append({"text": PLACE_TITLE[PLACE_NAMES[q]], "misconception": "wrong_place_identified",
                          "feedback": f"The {d} is not in the {PLACE_NAMES[q]} place."})
        return {"bloom": "remember", "type": "multipleChoice",
                "prompt": f"In the number {fmt(n)}, what is the place value of the digit {d}?",
                "choices": [{"text": PLACE_TITLE[place], "correct": True}, *wrong],
                "hints": ["Write the number under the labels: Th, H, T, O.", "Start from the ones place on the right."],
                "explanation": f"In {fmt(n)} the {d} is in the {place} place.",
                "visual": {"type": "placeValueChart", "value": n, "showLabels": True, "showWith": "hint"},
                "check": {"kind": "place_value", "number": n, "digit": d, "place": place, "ask": "place_name"}}

    def _pv_which_number(self):
        p = self.rng.choice([2, 3, 4])
        d = self.rng.randint(1, 9)
        def with_digit_at(pos: int, has: bool) -> int:
            while True:
                n = self.rng.randint(10000, 99999)
                s = list(str(n))
                idx = len(s) - 1 - pos
                if has:
                    s[idx] = str(d)
                elif s[idx] == str(d):
                    continue
                n = int("".join(s))
                if n >= 10000 and (str(n)[len(str(n)) - 1 - pos] == str(d)) == has:
                    return n
        correct = with_digit_at(p, True)
        wrongs = set()
        while len(wrongs) < 3:
            wrongs.add(with_digit_at(p, False))
        place = PLACE_NAMES[p]
        return {"bloom": "remember", "type": "multipleChoice",
                "prompt": f"Which number has the digit {d} in the {place} place?",
                "choices": [{"text": fmt(correct), "correct": True},
                            *[{"text": fmt(w), "misconception": "wrong_place_identified",
                               "feedback": f"In {fmt(w)} the {d} is not in the {place} place."} for w in sorted(wrongs)]],
                "hints": [f"The {place} place is number {p + 1} from the right."],
                "explanation": f"Only {fmt(correct)} has the digit {d} in the {place} place.",
                "check": {"kind": "digit_place", "digit": d, "place": place}}

    def _pv_total(self):
        n = self._digits_unique(5)
        p = self.rng.randrange(1, 5)
        d, place = int(str(n)[len(str(n)) - 1 - p]), PLACE_NAMES[p]
        return {"bloom": "understand", "type": "numericInput",
                "prompt": f"What is the total value of the digit {d} in {fmt(n)}?", "answer": str(d * 10 ** p),
                "hints": [f"Which place is the {d} in?", f"The {d} is in the {place} place. {d} {place} = ?"],
                "explanation": f"The {d} is in the {place} place, so its total value is {d} x {fmt(10 ** p)} = {fmt(d * 10 ** p)}.",
                "visual": {"type": "placeValueChart", "value": n, "highlight": [place], "showWith": "hint"},
                "check": {"kind": "place_value", "number": n, "digit": d, "place": place, "ask": "total_value"}}

    def _pv_build(self):
        x = [self.rng.randint(1, 9)] + [self.rng.randint(0, 9) for _ in range(4)]
        total = x[0] * 10000 + x[1] * 1000 + x[2] * 100 + x[3] * 10 + x[4]
        thing = self.rng.choice(["books", "pupils", "trees", "bags of maize"])
        return {"bloom": "apply", "type": "numericInput",
                "prompt": f"A store has {x[0]} ten-thousands, {x[1]} thousands, {x[2]} hundreds, {x[3]} tens and {x[4]} ones of {thing}. How many {thing} is that altogether?",
                "answer": str(total),
                "hints": ["Write each digit in its place, from ten-thousands to ones.", "If there are 0 of a place, write 0 there."],
                "explanation": f"{fmt(x[0] * 10000)} + {fmt(x[1] * 1000)} + {x[2] * 100} + {x[3] * 10} + {x[4]} = {fmt(total)} {thing}.",
                "visual": {"type": "placeValueChart", "value": total, "mode": "counters", "showWith": "hint"},
                "check": {"kind": "expr", "givens": x, "expr": f"{x[0]}*10000+{x[1]}*1000+{x[2]}*100+{x[3]}*10+{x[4]}", "equals": total}}

    def _pv_analyze(self):
        a = self.rng.randint(9000, 9999)
        b = self.rng.randint(10000, 12999)
        who = self.rng.choice(NAMES)
        return {"bloom": "analyze", "type": "multipleChoice",
                "prompt": f"{who} says {fmt(a)} is greater than {fmt(b)} because 9 is bigger than 1. What is wrong with this thinking?",
                "choices": [
                    {"text": f"{fmt(b)} has a ten-thousands place, so it has more digits and is greater.", "correct": True},
                    {"text": f"Nothing is wrong. {who} is correct.", "misconception": "compares_first_digit_only",
                     "feedback": "Compare the number of digits first. A 5-digit number is greater than a 4-digit number."},
                    {"text": "They should have compared the last digits instead.", "misconception": "compares_last_digit",
                     "feedback": "We compare from the largest place value, not from the ones."},
                    {"text": "They should have added the digits of each number.", "misconception": "adds_digits",
                     "feedback": "Adding digits does not tell us which number is greater."}],
                "hints": ["Count the digits in each number."],
                "explanation": f"{fmt(b)} has 5 digits and {fmt(a)} has 4 digits. The greater number is {fmt(max(a, b))}.",
                "check": {"kind": "expr", "givens": [a, b], "expr": f"max({a},{b})", "equals": max(a, b)}}
