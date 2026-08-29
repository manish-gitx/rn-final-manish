#!/usr/bin/env python3
"""Generate the report's diagrams and result charts as PNGs.

Everything here is drawn from values that were measured or read out of the codebase;
nothing is illustrative. The latency chart in particular reports the live admin console
reading, sample size included, rather than the demo-mode fixtures.

Usage:
    python3 scripts/docs/make_diagrams.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "figures"
OUT.mkdir(parents=True, exist_ok=True)

# Validated categorical slots 1-3 (light mode) from the data-viz reference palette.
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
SURFACE = "#fcfcfb"
INK = "#0b0b0b"
MUTED = "#52514e"
LINE = "#d8d6d1"
TIER_FILL = "#f2f1ee"

plt.rcParams.update(
    {
        "font.family": "sans-serif",
        # DejaVu carries the arrow glyphs; Kohinoor Telugu covers the Telugu label.
        "font.sans-serif": ["DejaVu Sans", "Kohinoor Telugu", "Helvetica Neue", "Arial"],
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
    }
)


def box(ax, x, y, w, h, label, sub="", fill="#ffffff", edge=LINE, fs=9, sub_fs=7.5):
    """Draw one rounded node with an optional second line of detail."""
    ax.add_patch(
        FancyBboxPatch(
            (x, y), w, h,
            boxstyle="round,pad=0,rounding_size=0.06",
            linewidth=1.0, edgecolor=edge, facecolor=fill,
        )
    )
    if sub:
        ax.text(x + w / 2, y + h * 0.60, label, ha="center", va="center",
                fontsize=fs, color=INK, weight="medium")
        ax.text(x + w / 2, y + h * 0.26, sub, ha="center", va="center",
                fontsize=sub_fs, color=MUTED)
    else:
        ax.text(x + w / 2, y + h / 2, label, ha="center", va="center",
                fontsize=fs, color=INK, weight="medium")


def arrow(ax, xy_from, xy_to, color=MUTED, style="-|>", lw=1.1, rad=0.0):
    ax.add_patch(
        FancyArrowPatch(
            xy_from, xy_to, arrowstyle=style, mutation_scale=11,
            linewidth=lw, color=color,
            connectionstyle=f"arc3,rad={rad}", shrinkA=2, shrinkB=2,
        )
    )


def canvas(w, h):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, h / w * 10)
    ax.axis("off")
    return fig, ax


def architecture():
    """Three-tier deployment architecture."""
    fig, ax = canvas(10, 6.4)

    # Bands are sized so each title clears the nodes inside it, and the inter-band
    # gaps stay empty so the connectors never cross a label.
    tiers = [
        ("PRESENTATION TIER", 4.62, 1.45),
        ("APPLICATION TIER — Google Cloud Run (us-central1), scales from zero  ·  HTTPS REST, Bearer JWT",
         2.70, 1.68),
        ("DATA TIER & EXTERNAL SERVICES", 0.50, 1.45),
    ]
    for title, y, h in tiers:
        ax.add_patch(
            FancyBboxPatch((0.25, y), 9.5, h, boxstyle="round,pad=0,rounding_size=0.08",
                           linewidth=0, facecolor=TIER_FILL)
        )
        ax.text(0.45, y + h - 0.17, title, fontsize=7.6, color=MUTED,
                weight="bold", va="top")

    # Presentation
    box(ax, 0.5, 4.78, 2.5, 0.72, "Flutter mobile app", "iOS · Android · Riverpod")
    box(ax, 3.2, 4.78, 2.2, 0.72, "Voice capture", "record → .m4a AAC")
    box(ax, 5.6, 4.78, 1.9, 0.72, "English / Telugu", "toggles without restart")
    box(ax, 7.7, 4.78, 2.0, 0.72, "Admin console", "static, served at /admin")

    # Application
    box(ax, 0.5, 3.28, 2.1, 0.68, "Auth", "Google OAuth → JWT")
    box(ax, 2.8, 3.28, 2.3, 0.68, "Conversation", "STT → LLM → TTS")
    box(ax, 5.3, 3.28, 2.0, 0.68, "Songs & Bible", "pagination, cache")
    box(ax, 7.5, 3.28, 2.2, 0.68, "Subscriptions", "Razorpay + webhooks")
    ax.add_patch(FancyBboxPatch((0.5, 2.80), 9.2, 0.40,
                                boxstyle="round,pad=0,rounding_size=0.06",
                                linewidth=1.0, edgecolor=LINE, facecolor="#ffffff"))
    ax.text(5.1, 3.00, "JWT middleware   ·   admin gate (is_admin)   ·   Multer   ·   "
                       "Zod validation   ·   feature flags   ·   Winston logging",
            ha="center", va="center", fontsize=7.4, color=MUTED)

    # Data tier
    box(ax, 0.5, 0.72, 2.2, 0.78, "Supabase", "PostgreSQL, 8 tables")
    box(ax, 2.9, 0.72, 2.2, 0.78, "OpenAI", "whisper-1 · gpt-4o", edge=BLUE)
    box(ax, 5.3, 0.72, 2.2, 0.78, "ElevenLabs", "multilingual TTS", edge=AQUA)
    box(ax, 7.7, 0.72, 2.0, 0.78, "Razorpay", "subscriptions")

    # Connectors stop at each band's edge rather than running into the nodes, which
    # keeps them out of the band titles.
    for x in (1.6, 3.9, 6.3, 8.6):
        arrow(ax, (x, 4.78), (x, 4.42))
        arrow(ax, (x, 2.80), (x, 1.52))

    ax.text(5.0, 0.30, "Stateless API — no session affinity, so any instance serves any request",
            ha="center", fontsize=7.4, color=MUTED, style="italic")

    fig.tight_layout(pad=0.3)
    fig.savefig(OUT / "fig-26-architecture.png", dpi=220, bbox_inches="tight")
    plt.close(fig)


def pipeline():
    """The timed three-stage conversation pipeline for one voice turn."""
    fig, ax = canvas(10, 4.3)

    stages = [
        (0.30, 2.05, "Record", "AAC .m4a\n≤ 10 MB", "#ffffff", LINE),
        (2.45, 2.05, "Whisper", "speech → text\nauto-detect", "#ffffff", BLUE),
        (4.60, 2.05, "GPT-4o", "+ last N turns\nJesus persona", "#ffffff", ORANGE),
        (6.75, 2.05, "ElevenLabs", "text → speech\nemotional tags", "#ffffff", AQUA),
        (8.85, 2.05, "Playback", "base64 MP3", "#ffffff", LINE),
    ]
    for x, y, title, sub, fill, edge in stages:
        w = 1.85 if title != "Playback" else 1.05
        ax.add_patch(FancyBboxPatch((x, y), w, 0.95,
                                    boxstyle="round,pad=0,rounding_size=0.07",
                                    linewidth=1.4, edgecolor=edge, facecolor=fill))
        ax.text(x + w / 2, y + 0.63, title, ha="center", fontsize=9.4,
                color=INK, weight="medium")
        ax.text(x + w / 2, y + 0.28, sub, ha="center", fontsize=7.2,
                color=MUTED, linespacing=1.35)

    for a, b in ((2.15, 2.45), (4.30, 4.60), (6.45, 6.75), (8.60, 8.85)):
        arrow(ax, (a, 2.52), (b, 2.52))

    # Measured stage timings, live instance.
    for x, w, ms, colour in ((2.45, 1.85, "4,004 ms", BLUE),
                             (4.60, 1.85, "3,471 ms", ORANGE),
                             (6.75, 1.85, "19,618 ms", AQUA)):
        ax.text(x + w / 2, 1.72, ms, ha="center", fontsize=8.2, color=colour, weight="bold")

    ax.text(5.0, 1.30, "measured p50 per stage — live instance, sample of 2 voice turns",
            ha="center", fontsize=7.4, color=MUTED, style="italic")

    ax.add_patch(FancyBboxPatch((0.30, 0.42), 9.45, 0.62,
                                boxstyle="round,pad=0,rounding_size=0.06",
                                linewidth=1.0, edgecolor=LINE, facecolor=TIER_FILL))
    ax.text(5.02, 0.73, "Every turn writes stt_ms · llm_ms · tts_ms · total_ms to conversation_logs "
                        "(fire-and-forget — logging never blocks a reply)",
            ha="center", fontsize=7.6, color=MUTED)

    ax.text(0.30, 3.42, "One voice turn", fontsize=10.5, color=INK, weight="bold")
    ax.text(0.30, 3.14, "The text path skips Whisper entirely and records stt_ms = 0, "
                        "which is what makes the cost of speech recognition measurable.",
            fontsize=7.8, color=MUTED)

    fig.tight_layout(pad=0.3)
    fig.savefig(OUT / "fig-27-voice-pipeline.png", dpi=220, bbox_inches="tight")
    plt.close(fig)


def er_diagram():
    """The eight Postgres tables and their relationships."""
    fig, ax = canvas(10, 6.8)

    # Row bands sit below the heading block so nothing overlaps the title. Row 1's
    # top edge is at ROW1 + height(4) = 5.93, which is clear of the subtitle.
    ROW1, ROW2, ROW3 = 4.25, 2.25, 0.35
    HEADER, ROW_H, PAD = 0.40, 0.26, 0.24

    def height(n):
        return HEADER + PAD + ROW_H * n

    tables = {
        "users":             (0.35, ROW1, 2.5, ["id (PK)", "email UNIQUE", "conversation_count", "is_admin"]),
        "conversation_logs": (3.45, ROW1, 3.0, ["id (PK)", "user_id (FK)", "language, input_mode",
                                                "stt_ms, llm_ms, tts_ms, total_ms"]),
        "subscriptions":     (7.05, ROW1, 2.6, ["id (PK)", "user_id (FK)", "plan_id (FK)", "status"]),
        "songs":             (0.35, ROW2, 2.5, ["id (PK)", "title", "audio_url", "image_url"]),
        "webhook_events":    (3.45, ROW2, 3.0, ["id (PK)", "event_type", "signature_valid", "payload"]),
        "plans":             (7.05, ROW2, 2.6, ["id (PK)", "price (paise)", "razorpay_plan_id", "is_prod"]),
        "feature_flags":     (0.35, ROW3, 2.5, ["key (PK)", "value (jsonb)", "description"]),
        "admin_audit_log":   (3.45, ROW3, 3.0, ["id (PK)", "admin_email", "action, target"]),
    }

    for name, (x, y, w, cols) in tables.items():
        h = height(len(cols))
        ax.add_patch(FancyBboxPatch((x, y), w, h,
                                    boxstyle="round,pad=0,rounding_size=0.05",
                                    linewidth=1.1, edgecolor=LINE, facecolor="#ffffff"))
        ax.add_patch(FancyBboxPatch((x, y + h - HEADER), w, HEADER,
                                    boxstyle="round,pad=0,rounding_size=0.05",
                                    linewidth=0, facecolor=TIER_FILL))
        ax.text(x + 0.14, y + h - HEADER / 2, name, fontsize=8.6, color=INK,
                weight="bold", va="center", family="monospace")
        for i, col in enumerate(cols):
            ax.text(x + 0.14, y + h - HEADER - PAD / 2 - (i + 0.5) * ROW_H + 0.03,
                    col, fontsize=6.9, color=MUTED, va="center", family="monospace")

    h4 = height(4)
    mid1 = ROW1 + h4 / 2
    arrow(ax, (2.85, mid1), (3.45, mid1), color=BLUE)
    arrow(ax, (6.45, mid1), (7.05, mid1), color=BLUE)
    arrow(ax, (8.35, ROW2 + h4), (8.35, ROW1), color=BLUE)

    ax.text(3.15, mid1 + 0.16, "1:N", fontsize=6.8, color=BLUE, ha="center")
    ax.text(6.75, mid1 + 0.16, "1:N", fontsize=6.8, color=BLUE, ha="center")
    ax.text(8.48, (ROW1 + ROW2 + h4) / 2, "N:1", fontsize=6.8, color=BLUE,
            ha="left", va="center")

    ax.text(0.35, 6.62, "Database schema", fontsize=10.5, color=INK, weight="bold")
    ax.text(0.35, 6.38, "Row-level security is enabled on every table. The API holds a service-tier key\n"
                        "that bypasses it, so authorization is enforced in application code instead.",
            fontsize=7.5, color=MUTED, va="top", linespacing=1.5)

    fig.tight_layout(pad=0.3)
    fig.savefig(OUT / "fig-28-er-diagram.png", dpi=220, bbox_inches="tight")
    plt.close(fig)


def latency_chart():
    """Where the seconds go — measured live, contrasted with the demo fixtures.

    Horizontal bars: the job is magnitude comparison across three named stages.
    Every bar is directly labelled, which is also the relief the palette validator
    requires for the aqua slot's sub-3:1 contrast on a light surface.
    """
    fig, ax = plt.subplots(figsize=(8.6, 3.5))

    stages = ["Speech to text\n(Whisper)", "AI response\n(GPT-4o)", "Text to speech\n(ElevenLabs)"]
    p50 = [4004, 3471, 19618]
    p95 = [4715, 3546, 20252]
    colours = [BLUE, ORANGE, AQUA]
    ypos = range(len(stages))

    ax.barh([y + 0.17 for y in ypos], p50, height=0.32, color=colours, zorder=3)
    ax.barh([y - 0.20 for y in ypos], p95, height=0.32, color=colours,
            alpha=0.34, zorder=3)

    for y, a, b in zip(ypos, p50, p95):
        ax.text(a + 320, y + 0.17, f"{a:,} ms", va="center", fontsize=8.6,
                color=INK, weight="bold")
        ax.text(b + 320, y - 0.20, f"{b:,} ms  p95", va="center", fontsize=7.6, color=MUTED)

    ax.set_yticks(list(ypos))
    ax.set_yticklabels(stages, fontsize=8.6, color=INK)
    ax.invert_yaxis()
    ax.set_xlim(0, 25200)
    ax.set_xlabel("milliseconds", fontsize=8, color=MUTED)
    ax.tick_params(axis="x", labelsize=7.6, colors=MUTED, length=0)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=LINE, linewidth=0.7, zorder=0)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left", "bottom"):
        ax.spines[side].set_visible(False)

    ax.set_title("Where the seconds go — live instance, p50 (solid) and p95 (faded)",
                 fontsize=10, color=INK, loc="left", pad=14, weight="bold")
    ax.text(0, -0.30, "End to end 27,457 ms p50.  Sample: last 2 turns (2 voice, 0 text). "
                      "Demo-mode fixtures report 3,030 ms and are not a measurement.",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, va="top")

    fig.tight_layout()
    fig.savefig(OUT / "fig-29-latency-breakdown.png", dpi=220, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    architecture()
    pipeline()
    er_diagram()
    latency_chart()
    for name in ("fig-26-architecture", "fig-27-voice-pipeline",
                 "fig-28-er-diagram", "fig-29-latency-breakdown"):
        path = OUT / f"{name}.png"
        print(f"  {path.relative_to(ROOT)}  ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
