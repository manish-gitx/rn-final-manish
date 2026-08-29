# Figure index — TalkToJesus capstone report

25 curated figures. Sources:

- **Video A** — `app demo.MP4` (3:50, 1206×2622, iPhone screen recording), Google Drive
  `124faeA_zm2HM7rPP_rWwJPsXSj6iN4QS`
- **Video B** — `talkToJesusDashboardd.mp4` (1:13, 1108×720), Google Drive
  `1UeTyKBB8uDYdNhWjS14s2lbwYxO7xW6p`
- **Screenshots** — native iOS captures in `screenshots/`

Frames were sampled every 2 s across the full runtime of both videos, reviewed, and the
sharpest frame for each distinct screen retained. Where a native screenshot existed for
the same screen it was preferred over a video frame.

## Mobile application

| Figure | File | Source | Shows |
|---|---|---|---|
| 1 | `fig-01-login.png` | `IMG_5821` | Login screen — "God First, Every Day.", Google sign-in button |
| 2 | `fig-02-google-consent.png` | `IMG_5822` | iOS Google OAuth consent sheet |
| 3 | `fig-03-home-english.png` | Video A 00:01 | Home screen, English — verse card, Jesus Songs / Bible buttons, voice bar |
| 4 | `fig-04-profile-drawer.png` | Video A 00:05 | Profile drawer — account details, Conversation History, Sign Out |
| 5 | `fig-05-home-telugu.png` | Video A 00:27 | Home screen after switching to తెలుగు — note `బైబిల్` and `యేసుతో మాట్లాడండి` |
| 6 | `fig-06-voice-recording.png` | Video A 01:00 | Recording state — cancel and stop controls |
| 7 | `fig-07-voice-processing.png` | Video A 01:25 | Processing state — "Listening to your heart" |
| 8 | `fig-08-conversation-history.png` | screenshot | Conversation History — a full turn with scripture citations |
| 9 | `fig-09-bible-telugu.png` | Video A 00:13 | Bible reader, Telugu — ఆది 1 (Genesis 1), OTSA translation |
| 10 | `fig-10-bible-translations.png` | Video A 00:17 | Translation selector — Telugu translations, OTSA selected |
| 11 | `fig-11-bible-book-chapter.png` | Video A 00:25 | Book and chapter selector with search |
| 12 | `fig-12-bible-english.png` | Video A 00:24 | Bible reader, English — John 1, GLW translation |
| 13 | `fig-13-songs-library.png` | screenshot | Hymn library — 12 bundled public-domain hymns with album art |
| 14 | `fig-14-audio-player.png` | screenshot | Hymn player — artwork, seek bar, transport controls |
| 15 | `fig-15-plans-sheet.png` | Video A 02:37 | Paywall — Monthly Plan, ₹499/month, 12 cycles |
| 16 | `fig-16-razorpay-checkout.png` | Video A 02:43 | Razorpay checkout — ₹499 total, contact details |
| 17 | `fig-17-payment-success.png` | Video A 03:24 | Payment confirmed — `pay_TVimmGbOHBRcjn` |
| 18 | `fig-18-home-subscribed.png` | Video A 03:36 | Home screen with an active subscription (green badge) |

## Admin console

Figures 19–23 are the console's built-in **demo mode** (`DEMO DATA` badge visible,
`demo@talktojesus.app`); the underlying numbers are fixtures, not production traffic.
Figures 24–25 are the **live** development instance.

| Figure | File | Source | Shows |
|---|---|---|---|
| 19 | `fig-19-admin-overview-demo.png` | Video B 00:06 | Demo-mode overview — stat cards, conversations/day, language split, latency |
| 20 | `fig-20-admin-users-demo.png` | Video B 00:26 | Demo-mode Users tab (fixture accounts — no real addresses) |
| 21 | `fig-21-admin-webhooks-demo.png` | Video B 00:36 | Webhook audit log with signature-verification status |
| 22 | `fig-22-admin-flags-demo.png` | Video B 00:44 | Runtime feature flags |
| 23 | `fig-23-admin-audit-demo.png` | Video B 00:48 | Admin audit trail |
| 24 | `fig-24-admin-overview-live.png` | Video B 00:52 | **Live** instance — 5 users, 2 turns, ₹1,497 MRR, 27.5 s average latency |
| 25 | `fig-25-admin-latency-live.png` | Video B 01:04 | **Live** per-stage latency — Whisper 4,004 ms, GPT-4o 3,471 ms, ElevenLabs 19,618 ms, end-to-end 27,457 ms (p50, sample of 2 voice turns) |

## Generated diagrams and charts

Drawn by `scripts/docs/make_diagrams.py` from values read out of the codebase and from
the measurements above — none of them are illustrative.

| Figure | File | Shows |
|---|---|---|
| 26 | `fig-26-architecture.png` | Three-tier architecture — Flutter client, Cloud Run API, Supabase and the external services |
| 27 | `fig-27-voice-pipeline.png` | One voice turn end to end, annotated with the measured per-stage timings |
| 28 | `fig-28-er-diagram.png` | The eight Postgres tables and their relationships |
| 29 | `fig-29-latency-breakdown.png` | Measured per-stage latency, p50 and p95, live instance |

The chart's three-colour palette was validated with the data-viz palette checker
(`--pairs all`, light mode): lightness band, chroma floor, colour-vision separation and
normal-vision floor all pass. The aqua slot sits below 3:1 against the light surface, so
every bar carries a visible direct label rather than relying on colour alone.

## Notes carried into the report

1. **Latency.** The "3–6 s pipeline" quoted in the Phase 3 document and the existing deck
   matches the demo-mode fixtures (3,030 ms end-to-end, figure 19), not a measurement. The
   live instance measured **27,457 ms p50** end-to-end, of which ElevenLabs text-to-speech
   is 19,618 ms — roughly 71 %. The sample is 2 voice turns and is reported as such.
2. **Defect.** Figure 8 shows the ElevenLabs emotional-control tags (`[gently]`,
   `[comfortingly]`, `[prayerfully]`) rendered verbatim to the user. These are markup for
   the speech engine and should be stripped before display.
3. **Privacy.** The live Users tab exposes real personal email addresses, so figure 20 uses
   the demo-mode table instead.
4. **Language fixtures.** Demo mode shows EN/HI/TA/ES/PT. The application supports only
   English and Telugu; those extra languages are fixture data.
