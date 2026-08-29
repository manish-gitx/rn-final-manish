#!/usr/bin/env python3
"""Build the code submission archive with every credential removed.

Two categories of secret have to be handled differently:

  * **Secret-bearing files** (`.env`, `.env.bak.*`, `google-services.json`,
    `GoogleService-Info.plist`, keystores) are excluded outright. They are
    configuration, not source, and a reviewer does not need them.
  * **Credentials hardcoded inside source files** cannot simply be dropped, because
    the surrounding file is real source the submission needs. Those values are
    redacted in the copy that goes into the archive, and the redaction is recorded in
    SECURITY-NOTE.txt so nothing is silently altered.

The archive is assembled from `git ls-files`, so build output, `node_modules`,
`.dart_tool`, Pods and anything else already ignored never enters it.

The script fails loudly if any known secret survives into the archive.

Usage:
    python3 scripts/docs/make_code_archive.py
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "deliverables" / "other" / "03-TalkToJesus-Source-Code.zip"
STAGE_NAME = "TalkToJesus-2023EBCS668"

# Tracked paths that must never enter the archive.
EXCLUDE_PATTERNS = [
    re.compile(p) for p in (
        r"(^|/)\.env($|\.)",
        r"(^|/)google-services\.json$",
        r"(^|/)GoogleService-Info\.plist$",
        r"(^|/)key\.properties$",
        r"\.(keystore|jks|p12|pem)$",
        r"(^|/)sentry\.properties$",
        r"(^|/)\.DS_Store$",
        # Large binaries that are documentation, not code.
        r"\.(docx|pptx)$",
        r"^WhatsApp Image",
        r"^~\$",
        # Build output that was committed to the repository by mistake.
        r"(^|/)build/",
        r"(^|/)\.symlinks/",
        r"(^|/)Pods/",
    )
]

# Live credentials hardcoded in source. Each is replaced by a clearly-marked stand-in.
REDACTIONS = [
    (
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJkMTRhZmQwMy1mMDRlLTQzM2UtOTFkOS05MDlkYzUzYmVlMjMiLCJpYXQiOjE3NjI0MjQzMDYsImV4cCI6MTc5Mzk2MDMwNn0.o8BccbLc8Vx-Ju47uC7owOGXeMKwbQxN1GR0unGdH7o",
        "REDACTED_FOR_SUBMISSION_supply_your_own_tester_jwt",
        "long-lived tester JWT",
    ),
    (
        "phc_6HuKQBC0LXXvL6nPeXsdM3JUbNexAWKBc7iyOn9YbhK",
        "REDACTED_FOR_SUBMISSION_posthog_project_key",
        "PostHog project key",
    ),
    (
        "https://9a8f5dbcb014f55c7077249034fc9ce3@o4510107037728768.ingest.us.sentry.io/4510107039694848",
        "REDACTED_FOR_SUBMISSION_sentry_dsn",
        "Sentry DSN",
    ),
]

TEXT_SUFFIXES = {
    ".dart", ".ts", ".js", ".json", ".yaml", ".yml", ".xml", ".plist", ".md",
    ".txt", ".html", ".sql", ".gradle", ".kts", ".properties", ".sh", ".swift",
    ".kt", ".java", ".h", ".m", ".pbxproj", ".cfg", ".lock", ".gitignore",
}

ENV_EXAMPLE = """\
# TalkToJesus backend configuration.
# Copy to .env and fill in. The code is authoritative for these names - note that
# two of them differ from the table in the repository README.

PORT=4040
NODE_ENV=development
LOG_LEVEL=info

# Supabase - the code reads SUPABASE_KEY, not SUPABASE_SERVICE_ROLE_KEY.
# This is a service-tier key and bypasses row-level security.
SUPABASE_URL=
SUPABASE_KEY=

# Signing secret for the application's own JWTs. Required - the module throws without it.
JWT_SECRET=

# Google OAuth - three separate client IDs, at least one required.
GOOGLE_CLIENT_ID_WEB=
GOOGLE_CLIENT_ID_IOS=
GOOGLE_CLIENT_ID_ANDROID=

# OpenAI - used for both Whisper transcription and GPT-4o generation.
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o
OPENAI_MAX_TOKENS=800
OPENAI_TEMPERATURE=0.7

# ElevenLabs - if the key is absent the app degrades to text-only replies.
ELEVENLABS_API_KEY=
ELEVENLABS_VOICE_ID=
ELEVENLABS_MODEL=eleven_multilingual_v2

# Razorpay - the DEV set is required when NODE_ENV is not production.
RAZORPAY_KEY_ID_DEV=
RAZORPAY_KEY_SECRET_DEV=
RAZORPAY_WEBHOOK_SECRET_DEV=
RAZORPAY_KEY_ID_PROD=
RAZORPAY_KEY_SECRET_PROD=
RAZORPAY_WEBHOOK_SECRET_PROD=

# Administrative console sign-in.
ADMIN_EMAIL=
ADMIN_PASSWORD=
"""


def security_note(redacted: list[tuple[str, int]], excluded: list[str]) -> str:
    lines = [
        "SECURITY NOTE - TalkToJesus code submission",
        "Manish Rachakonda (2023EBCS668)",
        "",
        "This archive has been prepared for submission. Credentials have been removed.",
        "Nothing else about the source has been altered.",
        "",
        "1. FILES EXCLUDED",
        "",
        "   Configuration files carrying live credentials were left out entirely:",
        "",
    ]
    for path in excluded:
        lines.append(f"     - {path}")
    lines += [
        "",
        "   Also excluded: build output, node_modules, .dart_tool, Pods, and the",
        "   submission documents (those are supplied separately).",
        "",
        "   A template is provided at TalkToJesus-backend/.env.example listing every",
        "   variable the code actually reads.",
        "",
        "2. VALUES REDACTED INSIDE SOURCE FILES",
        "",
        "   These credentials were hardcoded in source rather than in configuration.",
        "   The files are real source and are included, but the values are replaced",
        "   with REDACTED_FOR_SUBMISSION_* placeholders:",
        "",
    ]
    for description, count in redacted:
        lines.append(f"     - {description} ({count} occurrence{'s' if count != 1 else ''})")
    lines += [
        "",
        "   This is recorded as a limitation in the project report (Section 6.3) and",
        "   in the plagiarism compliance declaration. All three values are being",
        "   rotated; they should never have been committed.",
        "",
        "3. TO RUN THIS CODE",
        "",
        "   See 08-Installation-Guide.pdf, or Appendix B of the final project report.",
        "   In short: provision Supabase with the three .sql files in order, copy",
        "   .env.example to .env and fill it in, then:",
        "",
        "     cd TalkToJesus-backend && npm ci && npm run dev      # port 4040",
        "     cd talktojesus-frontend && flutter pub get",
        "     flutter run --dart-define=API_BASE_URL=http://localhost:4040",
        "",
        "   Firebase configuration files (google-services.json,",
        "   GoogleService-Info.plist) must be supplied from your own Firebase project.",
        "",
        "4. TESTS",
        "",
        "     cd TalkToJesus-backend && npm test        # 66 passing, no credentials needed",
        "     cd talktojesus-frontend && flutter test   # 75 passing",
        "",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    files = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()

    keep, excluded = [], []
    for rel in files:
        if any(p.search(rel) for p in EXCLUDE_PATTERNS):
            excluded.append(rel)
        else:
            keep.append(rel)

    redaction_counts = {description: 0 for _, _, description in REDACTIONS}

    with tempfile.TemporaryDirectory() as tmp:
        stage = Path(tmp) / STAGE_NAME
        for rel in keep:
            src = ROOT / rel
            if not src.exists():
                continue
            dst = stage / rel
            dst.parent.mkdir(parents=True, exist_ok=True)

            if src.suffix.lower() in TEXT_SUFFIXES or src.name.startswith("."):
                try:
                    text = src.read_text(encoding="utf-8")
                except (UnicodeDecodeError, ValueError):
                    shutil.copy2(src, dst)
                    continue
                for secret, replacement, description in REDACTIONS:
                    if secret in text:
                        redaction_counts[description] += text.count(secret)
                        text = text.replace(secret, replacement)
                dst.write_text(text, encoding="utf-8")
            else:
                shutil.copy2(src, dst)

        (stage / "TalkToJesus-backend" / ".env.example").write_text(ENV_EXAMPLE)
        note = security_note(
            [(d, c) for d, c in redaction_counts.items() if c], excluded
        )
        (stage / "SECURITY-NOTE.txt").write_text(note)

        # Verify: no known secret may survive anywhere in the staged tree.
        leaked = []
        for path in stage.rglob("*"):
            if not path.is_file():
                continue
            try:
                blob = path.read_text(encoding="utf-8", errors="ignore")
            except (OSError, ValueError):
                continue
            for secret, _, description in REDACTIONS:
                if secret in blob:
                    leaked.append(f"{description} in {path.relative_to(stage)}")
        if leaked:
            print("ABORTING - secrets survived into the archive:", file=sys.stderr)
            for item in leaked:
                print(f"  {item}", file=sys.stderr)
            return 1

        OUT.parent.mkdir(parents=True, exist_ok=True)
        if OUT.exists():
            OUT.unlink()
        with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for path in sorted(stage.rglob("*")):
                if path.is_file():
                    z.write(path, path.relative_to(stage.parent))

    print(f"  {OUT.relative_to(ROOT)}  ({OUT.stat().st_size // 1024} KB)")
    print(f"  {len(keep)} files included, {len(excluded)} excluded")
    for description, count in redaction_counts.items():
        if count:
            print(f"  redacted: {description} x{count}")
    print("  verified: no known secret present in the archive")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
