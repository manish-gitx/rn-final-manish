#!/usr/bin/env python3
"""Derive the standalone user manual and installation guide from the report appendices.

The checklist asks for a user manual and an installation guide as separate documents, and
the report needs them as appendices. Keeping one source and generating the other avoids
the two drifting apart.

Usage:
    python3 scripts/docs/split_appendices.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "src"

HEADER = """# {title}

**TalkToJesus — A Bilingual Voice-First AI Spiritual Companion**

Manish Rachakonda (2023EBCS668) · BSc Computer Science (Online Mode) · BITS Pilani
Supervisor: Swapnil Saurav · Academic Year 2025–2026

{note}

"""

TARGETS = [
    (
        "APPENDIX A — USER MANUAL",
        "07-user-manual.md",
        "User Manual",
        "This document is also included as Appendix A of the final project report. "
        "Figure numbers refer to that report; the figures themselves are indexed at "
        "`docs/figures/FIGURES.md`.",
    ),
    (
        "APPENDIX B — INSTALLATION GUIDE",
        "08-installation-guide.md",
        "Installation Guide",
        "This document is also included as Appendix B of the final project report.",
    ),
]


def section(text: str, heading: str) -> str:
    """Return the body of a top-level section, excluding its own heading."""
    start = text.index(f"# {heading}")
    body_start = start + len(f"# {heading}")
    following = re.search(r"\n# [A-Z]", text[body_start:])
    end = body_start + following.start() if following else len(text)
    return text[body_start:end].strip()


def build_test_report() -> None:
    """Derive the standalone test and validation report from Chapter 3."""
    body = (SRC / "03-chapter3.md").read_text()
    body = body.replace("# CHAPTER 3: TESTING, VALIDATION & RESULTS\n", "", 1).strip()
    header = HEADER.format(
        title="Test and Validation Report",
        note="This document is also Chapter 3 of the final project report. Section numbers "
             "are retained from that report so the two can be read together. Figure numbers "
             "refer to the report's figure list, indexed at `docs/figures/FIGURES.md`.",
    )
    out = SRC / "05-test-report.md"
    out.write_text(header + body + "\n")
    print(f"  {out.relative_to(ROOT)}  ({len(body.splitlines())} lines)")


def main() -> None:
    appendices = (SRC / "05-appendices.md").read_text()
    for heading, filename, title, note in TARGETS:
        body = section(appendices, heading)
        # Demote the appendix's own sub-headings by one level so the standalone
        # document has a single H1.
        body = re.sub(r"^## ", "## ", body, flags=re.MULTILINE)
        # Drop the cross-reference line that only makes sense inside the report.
        body = re.sub(r"^This appendix is written for.*?\n\n", "", body, flags=re.DOTALL | re.MULTILINE, count=1)
        body = re.sub(r"^Also published separately as .*\n\n", "", body, flags=re.MULTILINE, count=1)
        out = SRC / filename
        out.write_text(HEADER.format(title=title, note=note) + body + "\n")
        print(f"  {out.relative_to(ROOT)}  ({len(body.splitlines())} lines)")
    build_test_report()


if __name__ == "__main__":
    main()
