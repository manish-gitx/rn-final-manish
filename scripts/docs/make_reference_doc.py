#!/usr/bin/env python3
"""Build a clean pandoc reference document from the supplied example report.

The example report was shared as a *structural and stylistic* model. Handing it to
pandoc directly as `--reference-doc` works for styles, but pandoc also copies the
reference document's `word/media/` into every output — so all 17 of that report's
screenshots end up embedded inside our deliverables, undisplayed but present in the file.
Shipping another student's images inside this submission is not acceptable, so this
script produces a reference document that keeps the styles and discards everything else:

  * `word/media/*` is dropped entirely
  * `word/document.xml` is replaced with an empty body, preserving only the section
    properties so page size and margins carry over
  * image relationships are pruned from the document relationships part

Styles, theme, numbering, fonts and settings are copied through untouched, which is all
pandoc actually reads.

Usage:
    python3 scripts/docs/make_reference_doc.py
"""

from __future__ import annotations

import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "example-friends-report.docx"
TARGET = ROOT / "docs" / "reference.docx"

EMPTY_DOCUMENT = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    "<w:body>{sectpr}</w:body></w:document>"
)

DEFAULT_SECTPR = (
    "<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
    "<w:pgMar w:top=\"1440\" w:right=\"1440\" w:bottom=\"1440\" w:left=\"1440\" "
    "w:header=\"720\" w:footer=\"720\" w:gutter=\"0\"/></w:sectPr>"
)

IMAGE_REL = re.compile(
    r'<Relationship\b[^>]*Type="[^"]*/image"[^>]*/>', re.IGNORECASE
)


def section_properties(document_xml: str) -> str:
    """Lift the final <w:sectPr> so page size and margins survive."""
    matches = re.findall(r"<w:sectPr\b.*?</w:sectPr>", document_xml, re.DOTALL)
    return matches[-1] if matches else DEFAULT_SECTPR


def main() -> int:
    if not SOURCE.exists():
        print(f"source document missing: {SOURCE}")
        return 1

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    dropped = 0

    with zipfile.ZipFile(SOURCE) as src:
        original_document = src.read("word/document.xml").decode("utf-8", "replace")
        sectpr = section_properties(original_document)

        with zipfile.ZipFile(TARGET, "w", zipfile.ZIP_DEFLATED) as dst:
            for item in src.infolist():
                name = item.filename

                if name.startswith("word/media/"):
                    dropped += 1
                    continue

                if name == "word/document.xml":
                    dst.writestr(name, EMPTY_DOCUMENT.format(sectpr=sectpr))
                    continue

                data = src.read(name)

                if name == "word/_rels/document.xml.rels":
                    text = data.decode("utf-8", "replace")
                    text, removed = IMAGE_REL.subn("", text)
                    data = text.encode("utf-8")
                    if removed:
                        print(f"  pruned {removed} image relationship(s)")

                dst.writestr(item, data)

    size_before = SOURCE.stat().st_size // 1024
    size_after = TARGET.stat().st_size // 1024
    print(f"  dropped {dropped} media file(s)")
    print(f"  {TARGET.relative_to(ROOT)}  ({size_after} KB, from {size_before} KB)")

    # Sanity check: the result must still be a readable docx with the styles intact.
    with zipfile.ZipFile(TARGET) as check:
        names = check.namelist()
        assert "word/styles.xml" in names, "styles.xml missing from the reference document"
        assert not any(n.startswith("word/media/") for n in names), "media survived"
    print("  verified: styles present, no media")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
