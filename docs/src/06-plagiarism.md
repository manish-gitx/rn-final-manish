# PLAGIARISM COMPLIANCE AND ORIGINALITY DECLARATION

**TalkToJesus — A Bilingual Voice-First AI Spiritual Companion**

Manish Rachakonda (2023EBCS668) · BSc Computer Science (Online Mode) · BITS Pilani
Supervisor: Swapnil Saurav · Academic Year 2025–2026

_Covers all deliverables: the final project report, the project summary, the user manual, the installation guide, the test and validation report, the presentation, and the submitted source code._

## 1. Declaration

I, **Manish Rachakonda**, roll number **2023EBCS668**, declare that:

1. The work described in these deliverables is my own, carried out under the supervision of Swapnil Saurav.
2. It has not been submitted to any other university or institution for the award of any degree or diploma.
3. All source code in `TalkToJesus-backend/src/`, `talktojesus-frontend/lib/` and `talktojesus-frontend/test/` was written by me. No code was copied from another project or from a tutorial without being rewritten and understood.
4. Every third-party library, external service and media asset is acknowledged in Section 4, with its licence recorded as read from the package itself rather than assumed.
5. Where these deliverables restate material from my own earlier Phase 1, Phase 2 and Phase 3 submissions, those documents are cited, and Sections 1.6 and 3.6 of the report record every point at which the current work corrects or supersedes them.
6. Reported measurements are actual measurements. Where a figure is fixture or demonstration data rather than a measurement, it is labelled as such — see Section 3.5 of the report, which exists precisely to correct a figure that had been repeated without that distinction.

Name: **Manish Rachakonda**

Signature: **Manish Rachakonda**    Date: **25 August 2026**

**Supervisor's certification**

I certify that the work described in these deliverables was carried out by the candidate under my supervision.

Supervisor: Swapnil Saurav

Signature: **Swapnil Saurav**    Date: **25 August 2026**

## 2. Similarity check

A textual-overlap analysis was run so that this declaration carries measured figures rather than an unsupported assertion. The analysis was performed with a purpose-written script, `scripts/docs/similarity_check.py`, executed with Claude Code, and the script is included in the code submission so the figures can be re-derived.

**Method.** Word-level shingling. Both texts are lowercased, stripped of punctuation and collapsed to single spaces, then cut into overlapping eight-word windows. Overlap is the proportion of the report's distinct windows that also appear in a source. Eight words is long enough that ordinary technical phrasing does not collide by chance, and short enough to catch a lightly-edited sentence.

**Measured on the final report** (16,199 words; 16,026 distinct eight-word windows):

| Source | Overlap | Windows |
|---|---|---|
| Phase 1 — Problem Identification (candidate's own prior work) | 0.16 % | 25 |
| Phase 2 — Requirements & Architecture (candidate's own prior work) | 0.00 % | 0 |
| Phase 3 — Implementation & Validation (candidate's own prior work) | 0.02 % | 4 |
| Repository `README.md` (candidate's own) | 0.07 % | 11 |
| `TESTING.md` (candidate's own) | 0.16 % | 26 |
| `DEMO-SCRIPT.md` (candidate's own) | 0.01 % | 1 |
| **Combined against all declared sources** | **0.42 %** | **67** |
| **Original to this report** | **99.58 %** | **15,959** |

Every source in that table is the candidate's own prior work, cited as references 1 to 3 and in Section 3.

**Control measurement.** The report follows the chapter structure of an example capstone report shared with the candidate as a model of the expected shape. That document was measured as a control:

| Source | Overlap | Windows |
|---|---|---|
| Example report (structural model only) | 0.31 % | 49 |

All 49 matching windows were inspected individually. They fall into three groups, and none is content:

1. **Chapter and section headings** — for example "chapter 3 testing validation results 3 1 test plan". Both reports use the same prescribed chapter structure, so the headings coincide by construction.
2. **The standard declaration wording** — "has not been submitted to any other university or institution for the award of any degree", which is boilerplate common to every submission of this kind.
3. **Cover-page field labels** — "Program: BSc Computer Science (Online Mode)", "Institution: Birla Institute of Technology and Science", and one table header row.

Two sentences in an earlier draft echoed the example's phrasing more closely than the above — in Sections 1.1 and 1.5, where the report describes its own organisation. Both were identified by this analysis and rewritten before submission. That is recorded here rather than quietly corrected.

**Where the residual overlap comes from.** The functional and non-functional requirement statements in Section 3.2 of the report and the objectives in Section 1.3 are reproduced from the candidate's own Phase 1 and Phase 2 submissions, and are cited. Technology names, API endpoint paths, environment variable names, package names and licence identifiers also match external sources, because they are proper nouns and cannot be paraphrased. The longest single shared passage in the measurement above is a sixteen-word run of the objective statements, which is exactly this.

## 3. Document originality

**Written from scratch for this submission:** the entire final project report, the project summary, the user manual, the installation guide, the test and validation report, and this declaration.

**Reused from my own prior submissions, with citation:** the abstract's framing of the problem, the seven primary and four secondary objectives, the literature survey of five existing systems, and the twenty functional and nineteen non-functional requirement statements.

**Structural model.** The report follows the chapter structure of a capstone report format shared with me as an example of the expected shape — cover, declaration, abstract, lists, six chapters, references, appendices. **No table, figure, datum or finding from that document appears in this one**; all content concerns TalkToJesus and was written for this submission. The measured overlap is 0.31 %, and Section 2.2 accounts for every matching passage: chapter headings, standard declaration boilerplate and cover-page field labels. Two sentences describing the report's own organisation were found to echo that document's phrasing during the self-check and were rewritten before submission.

**No text in these deliverables was copied from any web page, book, article or another student's work.**

## 4. Code and asset provenance

### 4.1 Original work

| Component | Scale | Author |
|---|---|---|
| Backend API — routes, controllers, services, middleware | 28 endpoints | Candidate |
| Persona prompt engineering | ~90 lines, bilingual | Candidate |
| Flutter client — 8 screens, providers, repositories, services | — | Candidate |
| Database schema and migrations | 8 tables | Candidate |
| Administrative console | 995 lines, single file | Candidate |
| Automated test suites | 141 cases | Candidate |
| CI, Dockerfile, Cloud Build configuration | — | Candidate |
| Report figures and generation scripts | 29 figures | Candidate |

### 4.2 Third-party libraries

All are used as published dependencies under their own licences. None were modified or vendored into the source tree. Licences were read from each package's own metadata — `package.json` for npm packages, the `LICENSE` file in the pub cache for Dart packages — not assumed.

**Backend (npm).** MIT: `@supabase/supabase-js`, `axios`, `cors`, `express`, `form-data`, `jsonwebtoken`, `morgan`, `multer`, `razorpay`, `winston`, `zod`, `jest`, `ts-jest`, `ts-node`, `ts-node-dev`, `nodemon`, all `@types/*`. BSD-2-Clause: `dotenv`. Apache-2.0: `google-auth-library`, `typescript`.

**Client (pub.dev).** MIT: `flutter_riverpod`, `flutter_svg`, `audioplayers`, `permission_handler`, `razorpay_flutter`, `posthog_flutter`, `sentry_flutter`, `in_app_review`, `lottie`, `cupertino_icons`, `flutter_launcher_icons`. BSD-3-Clause: `google_sign_in`, `http`, `path`, `path_provider`, `shared_preferences`, `sqflite`, `record`, `connectivity_plus`, `crypto`, `google_fonts`, `shimmer`, `url_launcher`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_lints`.

**Typefaces.** Poppins and Lora, fetched at runtime by `google_fonts`, under the SIL Open Font License.

### 4.3 External services

OpenAI (Whisper, GPT-4o), ElevenLabs, Google Identity, Razorpay, Supabase and Google Cloud Run are used under their commercial terms.

**Scripture text is not authored or hosted by this project.** The Bible reader consumes a third-party public API at `bible.helloao.org`, which supplies all sixty-six books across six translations. This is credited in the report's Appendix E.

### 4.4 Bundled media — an open obligation

Twelve hymn excerpts (~42 s each, 64 kbps mono) were sourced from Wikimedia Commons and the Internet Archive, trimmed, faded and loudness-normalised. Nine are public domain. **Three are CC BY-SA:**

| Track | Licence |
|---|---|
| What a Friend We Have in Jesus | CC BY-SA 4.0 |
| Holy, Holy, Holy | CC BY-SA 4.0 |
| Abide With Me | CC BY-SA 3.0 |

CC BY-SA requires attribution and share-alike on redistribution. The full per-track record with source links is kept with the assets at `talktojesus-frontend/assets/music/hymns/ATTRIBUTION.md`, which itself notes that the credits should be surfaced in an about screen.

**The application currently has no about screen, so this obligation is unmet.** It is recorded as defect D-08 in the report, with the remedy listed in Section 6.4. It is declared here rather than omitted.

Album artwork is twelve public-domain paintings from the Metropolitan Museum of Art Open Access collection (CC0), centre-cropped and downscaled. Artists include Gerard David, Hans Memling, Eugène Delacroix, Petrus Christus, Ambrosius Benson, Sebastiano Ricci and Joos van Wassenhove.

## 5. Use of AI tools

AI coding assistance was used during development and during the preparation of these documents, in line with normal contemporary practice. All architectural decisions, all trade-offs, the measurement methodology and the conclusions drawn from it are the candidate's own. Every factual claim in the report was checked against the codebase, the captured test output or the recorded measurements before being written; the corrections in Sections 1.6 and 3.6 are the result of that checking.
