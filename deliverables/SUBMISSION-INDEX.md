# Viva Submission Index — TalkToJesus

**Manish Rachakonda · 2023EBCS668 · BSc Computer Science (Online Mode), BITS Pilani**
Supervisor: Swapnil Saurav · Academic Year 2025–2026
Repository: https://github.com/manish-gitx/rn-final-manish

Mapped against the supervisor's twelve-point viva checklist.

## Checklist status

| # | Checklist item | Deliverable | Status | Drive link |
|---|---|---|---|---|
| 1 | Project report, signed by supervisor | `01-Final-Project-Report.docx` / `.pdf` (103 pp) | Ready — **needs signature** | — |
| 2 | Summary with UVP, uploaded to shared drive | `02-Project-Summary.docx` / `.pdf` (8 pp) | Ready | _paste public link_ |
| 3 | Code submission (zip) | `03-TalkToJesus-Source-Code.zip` (376 files, 27 MB) | Ready — credentials removed | _paste public link_ |
| 4 | Source code link (GitHub) in a `.txt` | `04-Source-Code-Link.txt` | Ready | _paste public link_ |
| 5 | Test cases and validation report | `05-Test-and-Validation-Report.docx` / `.pdf` (39 pp), and Chapter 3 of the report | Ready | — |
| 6 | Plagiarism compliance | `06-Plagiarism-Compliance.docx` / `.pdf` | Ready — **needs supervisor signature** | — |
| 7 | User manual | `07-User-Manual.docx` / `.pdf` (12 pp), and Appendix A | Ready | — |
| 8 | Installation guide | `08-Installation-Guide.docx` / `.pdf` (12 pp), and Appendix B | Ready | — |
| 9 | Final presentation, BITS template | `09-TalkToJesus-Capstone-Final.pptx` / `.pdf` (10 slides) | Ready | — |
| 10 | Demo video link | `10-Demo-Video-Links.txt` | Ready — links verified public | already public |
| 11 | Marketing videos | — | **Not applicable** — see note below | — |
| 12 | Social media posters | `posters/` — 5 PNGs | Ready | _paste public link_ |

The checklist asks that items **2, 3, 4, 10, 11 and 12** be kept in Drive as public links and sent by email. Of the ones now in scope, that means **2, 3, 4, 10 and 12**.

## Before you submit

- [ ] **Sign the report.** `01-Final-Project-Report.docx` — the certificate page after the cover. The viva will not be conducted without the supervisor's signature.
- [ ] **Get the plagiarism declaration counter-signed** by your supervisor (`06`, Section 1).
- [ ] **Upload 02, 04 and 10 to Drive**, set each to "anyone with the link", and paste the links into the table above.
- [ ] **Read `SECURITY-NOTE.txt` inside the code archive.** It records what was excluded and which three credentials were redacted from source. Rotate all three — the tester JWT, the PostHog key and the Sentry DSN — since they were previously public on GitHub.
- [ ] **Delete the three `TalkToJesus-backend/.env.bak.*` files** from your working copy. They are not covered by `.gitignore`; the archive excludes them, but they are still on your disk.

## On checklist item 11 — marketing videos

The checklist qualifies this item with "if it is a product and applicable". No marketing
video was produced, because outreach for this project was carried out in person rather
than through social media: churches were visited directly and pastors were contacted
about the application. For a Telugu-speaking devotional audience reached through
congregations, that is a more direct channel than a social media video, and it is the
reason this item is recorded as not applicable rather than incomplete.

Posters (item 12) were produced and are in `posters/`:

| File | Size | Leads on |
|---|---|---|
| `01-speak-he-listens-1080x1080.png` | square | The core promise — "Speak. He listens." |
| `02-telugu-naa-bidda-1080x1080.png` | square | Telugu-first — యేసుతో మాట్లాడండి, with నా బిడ్డ |
| `03-features-1080x1350.png` | portrait | Voice, Bible and hymns across three real screens |
| `04-two-am-1920x1080.png` | landscape | "At 2 a.m., when there's no one to ask." |
| `05-how-it-works-1920x1080.png` | landscape | The three-step voice loop |

Regenerate with `python3 scripts/docs/make_posters.py`.

## Three things to know before the viva

These came out of preparing the documents and each contradicts something in your existing material. Better to hear them from me now than from an examiner.

**1. The pipeline is 27.5 seconds, not 3–6.** Your Phase 3 document and the old deck both say three to six seconds. That figure matches the admin console's *demonstration fixtures* (3,030 ms), which are hand-written constants in the console's JavaScript. The live instance measures **27,457 ms p50**, of which ElevenLabs speech synthesis is **19,618 ms — 71%**. NFR1 required five seconds, so the report records it as **not met**. The report also argues the probable cause: your persona prompt asks for two to four sentences and the model returns three paragraphs, so the synthesiser is rendering roughly five times more text than intended. That is a fixable prompt problem, and framing it that way is much stronger than being caught out on the number.

**2. The test count is 141, not 137.** Both suites were re-run for this submission: 66 backend (10 Jest suites) + 75 client (9 Flutter files), none failing. `TESTING.md`, `DEMO-SCRIPT.md` and the old deck all say 62/137; Phase 3 says 40 with two failing. Quote **141**.

**3. It is Flutter, not React Native.** The repository is called `rn-final-manish` and contains no React Native. Every document now says Flutter. Expect the question.

## Email draft

> **Subject:** Capstone viva deliverables — Manish Rachakonda (2023EBCS668) — TalkToJesus
>
> Dear Sir,
>
> Please find below the deliverables for my capstone project, **TalkToJesus — A Bilingual Voice-First AI Spiritual Companion**. All links are set to public access.
>
> **1. Project summary (checklist item 2)** — a four-section overview with the Unique Value Proposition, intended to be read before the viva. It covers the problem, the solution, the architecture and the measured results.
> _‹link›_
>
> **2. Source code link (checklist item 4)** — a text file containing the GitHub repository URL, the submitted commit SHA, a description of the repository layout and the commands to run both tiers.
> _‹link›_
>
> **3. Demonstration videos (checklist item 10)** — two recordings. The first (3 min 50 s) walks through the mobile application: Google sign-in, switching between English and Telugu, the Bible reader, the hymn library, a full voice conversation, the paywall, a live Razorpay UPI payment, and the conversation history. The second (1 min 13 s) shows the administrative console, including the per-stage latency instrumentation. The text file lists timestamps for each section of both recordings.
> _‹link›_
>
> The signed final project report, the test and validation report, the plagiarism compliance declaration, the user manual, the installation guide and the final presentation are attached / submitted separately as required.
>
> Two points I would like to flag in advance. First, the report records that the end-to-end conversation latency measures 27.5 seconds against a five-second non-functional requirement, so that requirement is **not met**; Section 3.5 sets out the measurement, identifies speech synthesis as 71% of it, and corrects the three-to-six second figure quoted in my Phase 3 document, which I traced to demonstration fixture data rather than a measurement. Second, the automated test count is now 141 across both tiers, all passing, which supersedes the 137 quoted in my earlier documents.
>
> Thank you,
> Manish Rachakonda
> 2023EBCS668
> 2023ebcs668@online.bits-pilani.ac.in

## Supporting material in the repository

| Path | Contents |
|---|---|
| `docs/figures/` | 29 report figures + `FIGURES.md` index + `index.html` to browse them |
| `docs/figures/print/` | Downscaled copies used by the `--compact` build |
| `docs/evidence/` | Raw `npm test` and `flutter test` output, and the extracted 141-case list |
| `docs/src/` | The Markdown sources for every document |
| `scripts/docs/` | `extract_tests.py`, `make_diagrams.py`, `make_reference_doc.py`, `split_appendices.py`, `build_docs.py`, `build_deck.py` |

To rebuild everything: `python3 scripts/docs/build_docs.py && python3 scripts/docs/build_deck.py`.
