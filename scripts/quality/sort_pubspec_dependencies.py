#!/usr/bin/env python3
"""Sort `dependencies`, `dev_dependencies`, and `dependency_overrides` blocks
in every pubspec.yaml under the project.

Detection of "is this already sorted?" is intentionally NOT this script's
job -- that's what the built-in `sort_pub_dependencies` analyzer lint is for
(enabled via very_good_analysis, runs as part of `flutter analyze` / CI).
This script exists purely to auto-fix violations that lint reports, since
`sort_pub_dependencies` has no `dart fix` support.

Usage:
    python scripts/quality/sort_pubspec_dependencies.py            # sort in place
    python scripts/quality/sort_pubspec_dependencies.py --dry-run  # preview diff only
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path
from typing import Final

SORTABLE_SECTIONS: Final[set[str]] = {
    "dependencies",
    "dev_dependencies",
    "dependency_overrides",
}

EXCLUDED_DIRECTORIES: Final[set[str]] = {
    ".dart_tool",
    ".fvm",  # FVM's cached/symlinked Flutter SDK checkout -- has its own
    # pubspec.yaml files (packages/flutter, packages/flutter_test, ...)
    # that must never be touched, and the cache is often shared across
    # projects, so writing to it here would corrupt other repos too.
    ".git",
    ".idea",
    ".vscode",
    "build",
    "coverage",
    "node_modules",
}

# Top-level section header, e.g. "dependencies:" (no leading whitespace).
SECTION_PATTERN: Final[re.Pattern[str]] = re.compile(
    r"^(dependencies|dev_dependencies|dependency_overrides):\s*(?:#.*)?$"
)

# A dependency entry, indented exactly two spaces, e.g. "  dio: ^5.0.0".
DEPENDENCY_PATTERN: Final[re.Pattern[str]] = re.compile(r"^  ([A-Za-z0-9_-]+):")


def dependency_name(block: list[str]) -> str:
    """Extract the normalized dependency name from a dependency block."""
    for line in block:
        match = DEPENDENCY_PATTERN.match(line)
        if match:
            return match.group(1).casefold()
    return ""


def split_dependency_blocks(
    lines: list[str],
) -> tuple[list[str], list[list[str]], list[str]]:
    """Split a section's lines into a preamble, one block per dependency,
    and any trailing comments/blank lines that follow the last dependency.

    Comments/blank lines directly above a dependency are kept attached to
    that dependency, so they move together when sorted -- this is the
    explicit rule for indented comments: they belong to whichever
    dependency comes immediately after them. Trailing blank lines/comments
    after the LAST dependency (e.g. the blank line separating this section
    from the next top-level key) are returned separately so sorting never
    drags them to a different position.
    """
    preamble: list[str] = []
    blocks: list[list[str]] = []
    pending: list[str] = []
    current: list[str] | None = None

    for line in lines:
        match = DEPENDENCY_PATTERN.match(line)

        if match:
            if current is not None:
                blocks.append(current)
            current = [*pending, line]
            pending = []
            continue

        is_blank_or_top_comment = not line.strip() or line.startswith("  #")

        if current is None:
            if is_blank_or_top_comment:
                pending.append(line)
            else:
                preamble.extend(pending)
                pending = []
                preamble.append(line)
            continue

        if is_blank_or_top_comment:
            # Could belong to this dependency (trailing) or the next one
            # (leading) -- resolved once we know what follows.
            pending.append(line)
            continue

        # Anything indented deeper (4+ spaces) is nested config for the
        # dependency currently being collected (path:, git:, version:...).
        current.extend(pending)
        pending = []
        current.append(line)

    if current is not None:
        blocks.append(current)
    else:
        preamble.extend(pending)
        pending = []

    # Whatever is left in `pending` here trailed the last dependency and
    # was never reattached -- keep it fixed at the end, not sorted with it.
    return preamble, blocks, pending


def sort_section(lines: list[str]) -> list[str]:
    preamble, blocks, trailing = split_dependency_blocks(lines)
    if len(blocks) <= 1:
        return lines
    sorted_blocks = sorted(blocks, key=dependency_name)
    return [
        *preamble,
        *(line for block in sorted_blocks for line in block),
        *trailing,
    ]


def sort_pubspec_content(content: str) -> str:
    had_trailing_newline = content.endswith("\n")
    lines = content.splitlines()
    output: list[str] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        section_match = SECTION_PATTERN.match(line)

        if not section_match or section_match.group(1) not in SORTABLE_SECTIONS:
            output.append(line)
            index += 1
            continue

        output.append(line)
        index += 1
        section_lines: list[str] = []

        while index < len(lines):
            current_line = lines[index]
            # A new top-level YAML key ends this section.
            if current_line and not current_line.startswith((" ", "\t")):
                break
            section_lines.append(current_line)
            index += 1

        output.extend(sort_section(section_lines))

    result = "\n".join(output)
    if had_trailing_newline:
        result += "\n"
    return result


def should_skip(relative_path: Path) -> bool:
    return any(part in EXCLUDED_DIRECTORIES for part in relative_path.parts)


def find_pubspecs(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("pubspec.yaml")
        if not should_skip(path.relative_to(root))
    )


def process_pubspec(path: Path, *, dry_run: bool, root: Path) -> bool:
    """Sort one pubspec and return whether its content would change."""
    original = path.read_text(encoding="utf-8")
    sorted_content = sort_pubspec_content(original)
    relative_path = path.relative_to(root)

    if original == sorted_content:
        print(f"[OK]        {relative_path}")
        return False

    if dry_run:
        print(f"[WOULD FIX] {relative_path}")
        diff = difflib.unified_diff(
            original.splitlines(keepends=True),
            sorted_content.splitlines(keepends=True),
            fromfile=str(relative_path),
            tofile=str(relative_path),
        )
        sys.stdout.writelines(diff)
        return True

    path.write_text(sorted_content, encoding="utf-8")
    print(f"[SORTED]    {relative_path}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview a unified diff of changes without writing anything.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path.cwd(),
        help="Project root to search from (default: current directory).",
    )
    args = parser.parse_args()
    root = args.root.resolve()

    if not root.is_dir():
        print(f"Error: not a valid directory: {root}", file=sys.stderr)
        return 2

    pubspecs = find_pubspecs(root)
    if not pubspecs:
        print(f"No pubspec.yaml found under {root}")
        return 0

    print(f"Found {len(pubspecs)} pubspec.yaml file(s):")
    changed = sum(
        process_pubspec(path, dry_run=args.dry_run, root=root)
        for path in pubspecs
    )

    if changed == 0:
        print("\nAll pubspec.yaml files are already sorted.")
    elif args.dry_run:
        print(f"\n{changed} file(s) would be sorted (run without --dry-run to apply).")
    else:
        print(f"\nSorted {changed} file(s).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
