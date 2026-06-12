#!/usr/bin/env python3
"""Update pipeline_state.md for the Experts sprint pipeline."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PIPELINE_FILE = ROOT / "pipeline_state.md"


def read_state() -> str:
    if not PIPELINE_FILE.exists():
        raise SystemExit(f"ERROR: {PIPELINE_FILE} not found")
    return PIPELINE_FILE.read_text(encoding="utf-8")


def write_state(content: str) -> None:
    PIPELINE_FILE.write_text(content, encoding="utf-8")


def set_status(content: str, sprint: int, marker: str) -> str:
    pattern = rf"- \[[ Xx]\] {sprint}: (.+)"
    replacement = rf"- [{marker}] {sprint}: \1"
    return re.sub(pattern, replacement, content)


def complete_sprint(sprint: int) -> None:
    content = read_state()
    content = set_status(content, sprint, "X")
    content = re.sub(r"## Status: \w+", "## Status: IN_PROGRESS", content)
    content = re.sub(
        r"## Current Sprint: \d+",
        f"## Current Sprint: {sprint + 1}",
        content,
    )
    write_state(content)
    print(f"Sprint {sprint} marked complete.")


def skip_sprint(sprint: int) -> None:
    content = read_state()
    pattern = rf"- \[[ Xx]\] {sprint}: (.+)"
    content = re.sub(pattern, rf"- [ ] {sprint}: \1 — skipped", content)
    content = re.sub(
        r"## Current Sprint: \d+",
        f"## Current Sprint: {sprint + 1}",
        content,
    )
    match = re.search(r"## Incidents: (\d+)", content)
    if match:
        incidents = int(match.group(1)) + 1
        content = re.sub(r"## Incidents: \d+", f"## Incidents: {incidents}", content)
    write_state(content)
    print(f"Sprint {sprint} marked skipped.")


def finish() -> None:
    content = read_state()
    content = re.sub(r"## Status: \w+", "## Status: COMPLETE", content)
    write_state(content)
    print("Pipeline marked complete.")


def show() -> None:
    print(read_state())


def main() -> None:
    if len(sys.argv) == 1:
      show()
      return

    command = sys.argv[1]
    if command == "show":
        show()
    elif command == "finish":
        finish()
    elif command in {"complete", "skip"} and len(sys.argv) >= 3:
        sprint = int(sys.argv[2])
        if command == "complete":
            complete_sprint(sprint)
        else:
            skip_sprint(sprint)
    else:
        raise SystemExit(
            "Usage: python3 scripts/update_pipeline.py "
            "complete|skip|finish|show [N]"
        )


if __name__ == "__main__":
    main()
