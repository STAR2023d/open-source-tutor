import shutil
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]


@pytest.fixture
def repo_copy(tmp_path):
    """A throwaway copy of the content pack + validator, so tests never touch real content."""
    root = tmp_path / "repo"
    shutil.copytree(REPO / "packages" / "content_pack", root / "packages" / "content_pack")
    (root / "tools" / "agents").mkdir(parents=True)
    shutil.copytree(REPO / "tools" / "agents" / "skill_specs", root / "tools" / "agents" / "skill_specs")
    shutil.copy(REPO / "tools" / "validate_content.py", root / "tools" / "validate_content.py")
    return root
