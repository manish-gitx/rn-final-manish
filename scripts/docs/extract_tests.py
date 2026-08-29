#!/usr/bin/env python3
"""Parse the captured Jest and flutter_test output into a structured test-case list.

The tables in the final report are generated from this, so every row corresponds to a
test that actually executed rather than to a hand-maintained list.

Usage:
    python3 scripts/docs/extract_tests.py            # writes docs/evidence/test-cases.json
    python3 scripts/docs/extract_tests.py --markdown # also prints a markdown table
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "docs" / "evidence"

# Jest --verbose: "PASS src/__tests__/..." then indented describe levels then "✓ name (3 ms)".
JEST_FILE = re.compile(r"^(PASS|FAIL)\s+(\S+)")
JEST_CASE = re.compile(r"^(\s+)([✓✕○])\s+(.*?)(?:\s+\(\d+\s*ms\))?$")
# flutter test: "00:01 +12: /abs/path/to/test.dart: Group name test name"
FLUTTER_CASE = re.compile(r"^\d\d:\d\d\s+\+(\d+)(?:\s+-\d+)?:\s+(\S+\.dart):\s+(.*)$")


def parse_jest(path: Path) -> list[dict]:
    """Return one record per executed Jest case, carrying its describe-block path."""
    cases: list[dict] = []
    current_file = ""
    stack: list[tuple[int, str]] = []  # (indent, describe title)

    for raw in path.read_text(errors="replace").splitlines():
        m = JEST_FILE.match(raw)
        if m:
            current_file = m.group(2)
            stack = []
            continue

        m = JEST_CASE.match(raw.rstrip())
        if m:
            indent, mark, title = len(m.group(1)), m.group(2), m.group(3).strip()
            while stack and stack[-1][0] >= indent:
                stack.pop()
            cases.append(
                {
                    "tier": "backend",
                    "file": current_file,
                    "group": " › ".join(t for _, t in stack),
                    "name": title,
                    "status": {"✓": "Pass", "✕": "Fail", "○": "Skipped"}[mark],
                }
            )
            continue

        # A describe header: indented, no tick marker, not a jest summary line.
        if raw.startswith("  ") and raw.strip() and not raw.lstrip().startswith(("✓", "✕", "○", "at ", "console.")):
            stripped = raw.rstrip()
            indent = len(stripped) - len(stripped.lstrip())
            title = stripped.strip()
            if title.startswith(("Test Suites:", "Tests:", "Snapshots:", "Time:", "Ran all")):
                continue
            while stack and stack[-1][0] >= indent:
                stack.pop()
            stack.append((indent, title))

    return cases


def parse_flutter(path: Path) -> list[dict]:
    """Return one record per executed Flutter case from `flutter test --reporter json`.

    The plain reporter reprints the previously-finished test name as the counter
    advances, so identical (file, name) pairs there are not distinct tests and
    de-duplicating that stream silently loses cases. The JSON event stream carries a
    stable per-test id, which is what this reads instead.
    """
    tests: dict[int, dict] = {}
    results: dict[int, str] = {}

    for raw in path.read_text(errors="replace").splitlines():
        raw = raw.strip()
        if not raw.startswith("{"):
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError:
            continue

        if event.get("type") == "testStart":
            test = event["test"]
            name = test.get("name", "")
            if name.startswith("loading "):
                continue
            tests[test["id"]] = {
                "name": name,
                "url": test.get("root_url") or test.get("url") or "",
            }
        elif event.get("type") == "testDone" and not event.get("hidden"):
            results[event["testID"]] = event.get("result", "unknown")

    status_of = {"success": "Pass", "failure": "Fail", "error": "Fail"}
    cases: list[dict] = []
    for test_id, meta in tests.items():
        if test_id not in results:
            continue
        cases.append(
            {
                "tier": "frontend",
                "file": meta["url"].split("/test/")[-1] if "/test/" in meta["url"] else meta["url"],
                "group": "",
                "name": meta["name"],
                "status": status_of.get(results[test_id], "Unknown"),
            }
        )
    return cases


def assign_ids(cases: list[dict]) -> list[dict]:
    """Stamp BE-nnn / FE-nnn identifiers so the report can reference individual rows."""
    counters = {"backend": 0, "frontend": 0}
    prefix = {"backend": "BE", "frontend": "FE"}
    for case in cases:
        counters[case["tier"]] += 1
        case["id"] = f"{prefix[case['tier']]}-{counters[case['tier']]:03d}"
    return cases


def main() -> int:
    backend_log = EVIDENCE / "backend-test-output.txt"
    frontend_log = EVIDENCE / "frontend-test-report.json"
    for log in (backend_log, frontend_log):
        if not log.exists():
            print(f"missing {log} - run the suites first", file=sys.stderr)
            return 1

    cases = assign_ids(parse_jest(backend_log) + parse_flutter(frontend_log))

    out = EVIDENCE / "test-cases.json"
    out.write_text(json.dumps(cases, indent=2, ensure_ascii=False))

    backend = [c for c in cases if c["tier"] == "backend"]
    frontend = [c for c in cases if c["tier"] == "frontend"]
    failed = [c for c in cases if c["status"] != "Pass"]

    print(f"backend  : {len(backend)} cases across {len({c['file'] for c in backend})} suites")
    print(f"frontend : {len(frontend)} cases across {len({c['file'] for c in frontend})} files")
    print(f"total    : {len(cases)}  ({len(failed)} not passing)")
    print(f"written  : {out.relative_to(ROOT)}")

    if "--markdown" in sys.argv:
        print()
        print("| ID | Suite | Case | Status |")
        print("|---|---|---|---|")
        for c in cases:
            label = f"{c['group']} › {c['name']}" if c["group"] else c["name"]
            print(f"| {c['id']} | `{Path(c['file']).name}` | {label} | {c['status']} |")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
