#!/usr/bin/env python3
"""Measure textual overlap between the capstone report and its declared sources.

This is a local self-check, not an institutional similarity report. It exists so the
plagiarism declaration can carry measured numbers for the overlap the candidate has
already declared — the restated requirements and objectives from the candidate's own
Phase 1-3 submissions — rather than an unsupported assertion that the overlap is small.

Method: word-level shingling. Text is lowercased, stripped of punctuation and collapsed
to single spaces, then cut into overlapping n-word windows. Overlap is the proportion of
the report's distinct shingles that also occur in a source. n=8 is the usual choice for
this kind of check: long enough that ordinary phrasing does not collide by chance, short
enough to catch a lightly-edited sentence.

Usage:
    python3 scripts/docs/similarity_check.py
    python3 scripts/docs/similarity_check.py --n 8 --show 12
"""

from __future__ import annotations

import argparse
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

TARGET = ROOT / "deliverables" / "01-Final-Project-Report.docx"
SOURCES = [
    ("Phase 1 — Problem Identification", ROOT / "Phase1-Group-Project.docx"),
    ("Phase 2 — Requirements & Architecture", ROOT / "Phase2-Group-Project.docx"),
    ("Phase 3 — Implementation & Validation", ROOT / "Phase3-Group-Project.docx"),
    ("Repository README", ROOT / "README.md"),
    ("TESTING.md", ROOT / "TESTING.md"),
    ("DEMO-SCRIPT.md", ROOT / "DEMO-SCRIPT.md"),
]
# The structural model. Overlap here should be ~0; anything else needs explaining.
CONTROL = ("Example report (structural model only)", ROOT / "example-friends-report.docx")


def read_docx(path: Path) -> str:
    with zipfile.ZipFile(path) as z:
        xml = z.read("word/document.xml").decode("utf-8", "replace")
    xml = re.sub(r"</w:p>", "\n", xml)
    return re.sub(r"<[^>]+>", " ", xml)


def load(path: Path) -> str:
    if not path.exists():
        return ""
    return read_docx(path) if path.suffix == ".docx" else path.read_text(errors="replace")


def normalise(text: str) -> list[str]:
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return text.split()


def shingles(words: list[str], n: int) -> set[tuple[str, ...]]:
    return {tuple(words[i:i + n]) for i in range(len(words) - n + 1)}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=8, help="shingle length in words")
    ap.add_argument("--show", type=int, default=10, help="longest shared passages to print")
    args = ap.parse_args()

    if not TARGET.exists():
        print(f"missing {TARGET} — build the report first")
        return 1

    report_words = normalise(load(TARGET))
    report = shingles(report_words, args.n)
    print(f"Report: {len(report_words):,} words, {len(report):,} distinct {args.n}-word shingles\n")

    rows = []
    matched_all: set[tuple[str, ...]] = set()

    for label, path in SOURCES + [CONTROL]:
        if not path.exists():
            rows.append((label, None, None))
            continue
        source_words = normalise(load(path))
        source = shingles(source_words, args.n)
        shared = report & source
        pct = 100.0 * len(shared) / len(report) if report else 0.0
        rows.append((label, pct, len(shared)))
        if path != CONTROL[1]:
            matched_all |= shared

    combined = 100.0 * len(matched_all) / len(report) if report else 0.0

    width = max(len(r[0]) for r in rows)
    print(f"{'Source':{width}}  {'Overlap':>8}  {'Shingles':>9}")
    print("-" * (width + 21))
    for label, pct, count in rows:
        if pct is None:
            print(f"{label:{width}}  {'n/a':>8}  {'-':>9}")
        else:
            print(f"{label:{width}}  {pct:7.2f}%  {count:9,}")
    print("-" * (width + 21))
    print(f"{'Combined (declared sources)':{width}}  {combined:7.2f}%  {len(matched_all):9,}")
    print(f"{'Original to this report':{width}}  {100 - combined:7.2f}%  "
          f"{len(report) - len(matched_all):9,}")

    # Longest contiguous shared runs, which is what a reader would actually notice.
    print(f"\nLongest passages shared with the declared sources (top {args.show}):")
    runs, current = [], []
    for i in range(len(report_words) - args.n + 1):
        if tuple(report_words[i:i + args.n]) in matched_all:
            current.append(i)
        else:
            if current:
                runs.append((current[0], current[-1] + args.n))
                current = []
    if current:
        runs.append((current[0], current[-1] + args.n))
    runs.sort(key=lambda r: r[1] - r[0], reverse=True)
    for start, end in runs[:args.show]:
        text = " ".join(report_words[start:end])
        print(f"  [{end - start:3d} words] {text[:150]}{'...' if len(text) > 150 else ''}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
