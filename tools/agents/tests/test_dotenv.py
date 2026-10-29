import os

from hesabu_agents.content_io import load_dotenv
from hesabu_agents.llm import GeminiLLM, LLMError

import pytest


def test_dotenv_loads_without_overriding(tmp_path, monkeypatch):
    monkeypatch.delenv("HESABU_TEST_A", raising=False)
    monkeypatch.delenv("HESABU_TEST_B", raising=False)
    monkeypatch.setenv("HESABU_TEST_KEEP", "from-shell")
    f = tmp_path / ".env"
    f.write_text("# comment\n\nHESABU_TEST_A=abc123\nexport HESABU_TEST_B=\"quoted value\"\nHESABU_TEST_KEEP=from-file\nnot a line\n")
    names = load_dotenv(f)
    assert os.environ["HESABU_TEST_A"] == "abc123"
    assert os.environ["HESABU_TEST_B"] == "quoted value"
    assert os.environ["HESABU_TEST_KEEP"] == "from-shell"     # the shell wins
    assert sorted(names) == ["HESABU_TEST_A", "HESABU_TEST_B"]  # names only, never values


def test_missing_dotenv_is_fine(tmp_path):
    assert load_dotenv(tmp_path / "nope.env") == []


def test_missing_key_gives_a_friendly_message(monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    with pytest.raises(LLMError, match="hesabu/.env"):
        GeminiLLM("some-model")
