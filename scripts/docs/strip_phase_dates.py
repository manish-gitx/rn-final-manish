#!/usr/bin/env python3
"""Remove the "Date of Submission" field from the Phase 1-3 documents.

Each phase document's cover page carries a "Date of Submission:" label followed by a
separate paragraph holding the date. Both paragraphs are removed. Nothing else in the
documents is touched — the rest of `document.xml` and every other part of the package
is copied through byte-for-byte.

The originals are tracked in git at commit ccfb64b, so `git checkout -- Phase*.docx`
restores them.

Usage:
    python3 scripts/docs/strip_phase_dates.py           # report what would change
    python3 scripts/docs/strip_phase_dates.py --apply   # rewrite the files
"""

from __future__ import annotations

import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGETS = [
    ROOT / "Phase1-Group-Project.docx",
    ROOT / "Phase2-Group-Project.docx",
    ROOT / "Phase3-Group-Project.docx",
]

PARAGRAPH = re.compile(r"<w:p\b.*?</w:p>", re.DOTALL)
LABEL = re.compile(r"Date\s*of\s*Submission", re.I)
# A paragraph that is essentially just a date, e.g. "February 17, 2026".
DATE_ONLY = re.compile(
    r"^\s*(?:\d{1,2}\s+)?(January|February|March|April|May|June|July|August|September|October|November|December)"
    r"\s+\d{1,2},?\s+\d{4}\s*$",
    re.I,
)


def text_of(paragraph_xml: str) -> str:
    return " ".join(re.sub(r"<[^>]+>", "", paragraph_xml).split())


def strip(document_xml: str) -> tuple[str, list[str]]:
    """Drop the label paragraph and, if it follows, the bare date paragraph."""
    paragraphs = list(PARAGRAPH.finditer(document_xml))
    drop_spans: list[tuple[int, int]] = []
    removed: list[str] = []

    for i, match in enumerate(paragraphs):
        body = text_of(match.group(0))
        if not LABEL.search(body):
            continue
        drop_spans.append(match.span())
        removed.append(body or "(empty label paragraph)")

        # The value usually sits in the next paragraph; skip blanks in between.
        for follower in paragraphs[i + 1:i + 4]:
            value = text_of(follower.group(0))
            if not value:
                continue
            if DATE_ONLY.match(value):
                drop_spans.append(follower.span())
                removed.append(value)
            break

    for start, end in sorted(drop_spans, reverse=True):
        document_xml = document_xml[:start] + document_xml[end:]
    return document_xml, removed


def main() -> int:
    apply = "--apply" in sys.argv
    changed = 0

    for path in TARGETS:
        if not path.exists():
            print(f"  {path.name}: missing")
            continue

        with zipfile.ZipFile(path) as src:
            document = src.read("word/document.xml").decode("utf-8")
            items = src.infolist()
            payloads = {item.filename: src.read(item.filename) for item in items}

        updated, removed = strip(document)
        if not removed:
            print(f"  {path.name}: no submission date found")
            continue

        print(f"  {path.name}: removing {removed}")
        changed += 1
        if not apply:
            continue

        payloads["word/document.xml"] = updated.encode("utf-8")
        with tempfile.NamedTemporaryFile(delete=False, suffix=".docx") as tmp:
            temp_path = Path(tmp.name)
        with zipfile.ZipFile(temp_path, "w", zipfile.ZIP_DEFLATED) as dst:
            for item in items:
                dst.writestr(item, payloads[item.filename])
        shutil.move(str(temp_path), str(path))

    if not apply and changed:
        print("\n  dry run — re-run with --apply to rewrite the files")
        print("  originals are in git: git checkout -- Phase*.docx")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
