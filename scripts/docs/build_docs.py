#!/usr/bin/env python3
"""Assemble the Markdown sources into the submission deliverables.

The report is built with pandoc using `example-friends-report.docx` as the reference
document, so the output carries that document's styles rather than pandoc's defaults.
PDFs are produced with LibreOffice.

Usage:
    python3 scripts/docs/build_docs.py             # full-resolution figures
    python3 scripts/docs/build_docs.py --compact   # downscaled figures, ~10 MB
    python3 scripts/docs/build_docs.py --no-pdf    # skip the PDF conversion
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "src"
OUT = ROOT / "deliverables" / "docx"
PDF_OUT = ROOT / "deliverables" / "pdf"
BUILD = ROOT / "docs" / ".build"
REFERENCE = ROOT / "docs" / "reference.docx"

REPORT_PARTS = [
    "00-front.md",
    "01-chapter1.md",
    "02-chapter2.md",
    "03-chapter3.md",
    "04-chapters456.md",
    "05-appendices.md",
]

# Deliverables that are a single source file rather than an assembled set.
STANDALONE = [
    ("00-links.md", "00-Submission-Links.docx"),
    ("02-summary.md", "02-Project-Summary.docx"),
    ("05-test-report.md", "05-Test-and-Validation-Report.docx"),
    ("06-plagiarism.md", "06-Plagiarism-Compliance.docx"),
    ("07-user-manual.md", "07-User-Manual.docx"),
    ("08-installation-guide.md", "08-Installation-Guide.docx"),
]


FIGURES = ROOT / "docs" / "figures"


def expand(text: str) -> str:
    """Substitute the generated-table placeholders."""
    for token, filename in (("{{TEST_TABLE}}", "_test-table.md"),
                            ("{{SUITE_TABLE}}", "_suite-table.md")):
        if token in text:
            table = (SRC / filename).read_text()
            text = text.replace(token, table)
    return text


def use_print_figures(text: str) -> str:
    """Point image references at the downscaled print copies.

    Only used when `--compact` is passed. By default the report embeds the
    full-resolution lossless figures, which costs roughly 28 MB but keeps the
    screenshots legible when a reader zooms in. `--compact` trades that for a ~10 MB
    document by substituting `docs/figures/print/` — JPEG for the photographic
    screenshots, PNG for the flat-colour diagrams.
    """

    def swap(match: re.Match[str]) -> str:
        stem = Path(match.group(1)).stem
        for candidate in (FIGURES / "print" / f"{stem}.jpg", FIGURES / "print" / f"{stem}.png"):
            if candidate.exists():
                return f"](../figures/print/{candidate.name})"
        return match.group(0)

    return re.sub(r"\]\((\.\./figures/[^)]+)\)", swap, text)


def size_images(text: str) -> str:
    """Give every figure an explicit size so none overflows the page.

    Pandoc embeds images at their natural pixel size, which for a 1206x2622 phone
    screenshot works out at 6.3 x 13.6 inches — taller than the 9.7-inch usable page
    height, so each one consumed more than a full page. Portrait figures are therefore
    capped by height and landscape figures by width.
    """
    from PIL import Image

    PORTRAIT_HEIGHT = "4.3in"
    LANDSCAPE_WIDTH = "6.1in"

    def swap(match: re.Match[str]) -> str:
        rel = match.group(1)
        path = (SRC / rel).resolve()
        if not path.exists():
            return match.group(0)
        with Image.open(path) as img:
            width, height = img.size
        attr = PORTRAIT_HEIGHT if height > width else LANDSCAPE_WIDTH
        key = "height" if height > width else "width"
        return f"{match.group(0)}{{{key}={attr}}}"

    return re.sub(r"!\[[^\]]*\]\((\.\./figures/[^)]+)\)", swap, text)


def pandoc(markdown: str, output: Path, toc: bool) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    staged = BUILD / (output.stem + ".md")
    staged.write_text(markdown)

    cmd = [
        "pandoc", str(staged),
        "-o", str(output),
        f"--reference-doc={REFERENCE}",
        "--from=markdown+pipe_tables+implicit_figures+yaml_metadata_block",
        # Image paths in the sources are relative to docs/src.
        f"--resource-path={SRC}:{ROOT}",
    ]
    if toc:
        cmd += ["--toc", "--toc-depth=2"]

    subprocess.run(cmd, check=True, cwd=ROOT)
    print(f"  {output.relative_to(ROOT)}  ({output.stat().st_size // 1024} KB)")


def to_pdf(docx: Path) -> None:
    PDF_OUT.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["soffice", "--headless", "--convert-to", "pdf", "--outdir", str(PDF_OUT), str(docx)],
        check=True, capture_output=True, cwd=ROOT,
    )
    pdf = PDF_OUT / (docx.stem + ".pdf")
    if pdf.exists():
        print(f"  {pdf.relative_to(ROOT)}  ({pdf.stat().st_size // 1024} KB)")


def main() -> int:
    if not REFERENCE.exists():
        print("reference document missing; generating it...")
        subprocess.run([sys.executable, str(ROOT / "scripts" / "docs" / "make_reference_doc.py")],
                       check=True, cwd=ROOT)
    if not shutil.which("pandoc"):
        print("pandoc not found on PATH", file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    built: list[Path] = []

    compact = "--compact" in sys.argv
    figures = use_print_figures if compact else (lambda text: text)
    print(f"Building the final report ({'compact' if compact else 'full-resolution'} figures)...")
    report = "\n\n".join(size_images(figures(expand((SRC / part).read_text())))
                          for part in REPORT_PARTS)
    target = OUT / "01-Final-Project-Report.docx"
    pandoc(report, target, toc=True)
    built.append(target)

    for source, name in STANDALONE:
        path = SRC / source
        if not path.exists():
            continue
        target = OUT / name
        pandoc(size_images(figures(expand(path.read_text()))), target, toc=False)
        built.append(target)

    if "--no-pdf" not in sys.argv:
        if not shutil.which("soffice"):
            print("soffice not found; skipping PDF conversion", file=sys.stderr)
        else:
            print("Converting to PDF...")
            for docx in built:
                to_pdf(docx)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
