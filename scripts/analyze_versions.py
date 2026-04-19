#!/usr/bin/env python3
"""Generate analysis.md inside each vN snapshot by diffing code files.

Walks ``snapshots/code-guides/v1, v2, v3, ...`` in order. For every version,
compares each of the 6 CODE_*.md files against the same file in the previous
version and writes ``analysis.md`` listing exactly what changed per file.

This script only reads the snapshot folders — it never talks to git, so the
resulting ``analysis.md`` files have no trace of commits, hashes, authors or
dates. ``v1`` gets an "initial" analysis (all files added).

Usage:
    python scripts/analyze_versions.py [--root snapshots/code-guides]
"""

from __future__ import annotations

import argparse
import difflib
import re
from pathlib import Path

TARGET_BASENAMES = [
    "CODE_F00.md",
    "CODE_F01.md",
    "CODE_F02.md",
    "CODE_PAI.md",
    "CODE_PBO.md",
    "CODE_TOP.md",
]
SNAPSHOT_ROOT_DEFAULT = "snapshots/code-guides"
VERSION_RE = re.compile(r"^v(\d+)$")


def sorted_versions(root: Path) -> list[Path]:
    entries: list[tuple[int, Path]] = []
    for child in root.iterdir():
        if not child.is_dir():
            continue
        m = VERSION_RE.match(child.name)
        if m:
            entries.append((int(m.group(1)), child))
    entries.sort(key=lambda item: item[0])
    return [path for _, path in entries]


def read_lines(path: Path) -> list[str] | None:
    if not path.is_file():
        return None
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def line_counts(diff_lines: list[str]) -> tuple[int, int]:
    added = removed = 0
    for line in diff_lines:
        if line.startswith("+++") or line.startswith("---"):
            continue
        if line.startswith("+"):
            added += 1
        elif line.startswith("-"):
            removed += 1
    return added, removed


def classify(prev: list[str] | None, curr: list[str] | None) -> str:
    if prev is None and curr is not None:
        return "added"
    if prev is not None and curr is None:
        return "removed"
    if prev == curr:
        return "unchanged"
    return "modified"


def render_file_section(
    name: str, prev_lines: list[str] | None, curr_lines: list[str] | None
) -> list[str]:
    status = classify(prev_lines, curr_lines)
    lines = [f"### {name} — {status}", ""]

    if status == "unchanged":
        lines.append("_(no changes)_")
        lines.append("")
        return lines

    if status == "added":
        total = len(curr_lines or [])
        lines.append(f"`+{total} / -0 lines` (new file)")
        lines.append("")
        if curr_lines:
            lines.append("```diff")
            lines.extend(f"+{line.rstrip(chr(10))}" for line in curr_lines)
            lines.append("```")
            lines.append("")
        return lines

    if status == "removed":
        total = len(prev_lines or [])
        lines.append(f"`+0 / -{total} lines` (file removed)")
        lines.append("")
        if prev_lines:
            lines.append("```diff")
            lines.extend(f"-{line.rstrip(chr(10))}" for line in prev_lines)
            lines.append("```")
            lines.append("")
        return lines

    diff = list(
        difflib.unified_diff(
            prev_lines or [],
            curr_lines or [],
            fromfile=f"previous/{name}",
            tofile=f"current/{name}",
            n=3,
        )
    )
    added, removed = line_counts(diff)
    lines.append(f"`+{added} / -{removed} lines`")
    lines.append("")
    if diff:
        lines.append("```diff")
        lines.extend(entry.rstrip("\n") for entry in diff)
        lines.append("```")
    else:
        lines.append("_(no textual difference)_")
    lines.append("")
    return lines


def write_analysis(version_dir: Path, prev_dir: Path | None, index: int) -> None:
    out_lines = [f"# Analysis v{index}", ""]
    any_change = False

    for name in TARGET_BASENAMES:
        curr = read_lines(version_dir / name)
        prev = read_lines(prev_dir / name) if prev_dir is not None else None
        status = classify(prev, curr)
        if status == "unchanged":
            continue
        any_change = True
        out_lines.extend(render_file_section(name, prev, curr))

    if not any_change:
        out_lines.append("_(no code changes in this version)_")
        out_lines.append("")

    out_lines.append("## Files in this version")
    out_lines.append("")
    for name in TARGET_BASENAMES:
        present = (version_dir / name).is_file()
        out_lines.append(f"- `{name}` — {'present' if present else 'missing'}")

    (version_dir / "analysis.md").write_text("\n".join(out_lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", default=SNAPSHOT_ROOT_DEFAULT)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"Snapshot root not found: {root}")
        return 1

    versions = sorted_versions(root)
    if not versions:
        print(f"No v<N> folders found under {root}")
        return 0

    prev_dir: Path | None = None
    for index, version_dir in enumerate(versions, start=1):
        write_analysis(version_dir, prev_dir, index)
        print(f"[ok] {version_dir.name} analysis.md written")
        prev_dir = version_dir

    print(f"\nDone. analyzed {len(versions)} versions under {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
