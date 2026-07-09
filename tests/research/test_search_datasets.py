"""Tests for the consolidated search_datasets.py script."""
import subprocess
import sys
from pathlib import Path

SCRIPT_PATH = Path(__file__).parent.parent.parent / "research" / "rlhf-dataset-search" / "search_datasets.py"


class TestSearchDatasets:
    """Smoke tests for search_datasets.py CLI."""

    def test_help_flag(self):
        """--help should exit 0 and show usage."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--help"],
            capture_output=True, text=True
        )
        assert result.returncode == 0
        assert "usage:" in result.stdout.lower() or "usage:" in result.stderr.lower()

    def test_huggingface_source_flag(self):
        """--source huggingface should be accepted."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--source", "huggingface", "--query", "test", "--max-results", "1"],
            capture_output=True, text=True, timeout=10
        )
        # May fail due to network, but should not crash with argparse error
        assert result.returncode != 2  # exit code 2 = argparse error

    def test_arxiv_source_flag(self):
        """--source arxiv should be accepted."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--source", "arxiv", "--query", "test", "--max-results", "1"],
            capture_output=True, text=True, timeout=10
        )
        assert result.returncode != 2  # exit code 2 = argparse error

    def test_github_source_flag(self):
        """--source github should be accepted."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--source", "github", "--query", "test", "--max-results", "1"],
            capture_output=True, text=True, timeout=10
        )
        assert result.returncode != 2  # exit code 2 = argparse error

    def test_invalid_source(self):
        """Invalid --source should fail."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), "--source", "invalid_source"],
            capture_output=True, text=True
        )
        assert result.returncode != 0
