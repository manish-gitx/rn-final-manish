# REFERENCES

1. Rachakonda, M. (2026). *Study Project Phase 1: Problem Identification and Planning — Talk to Jesus*. BITS Pilani.
2. Rachakonda, M. (2026). *Study Project Phase 2: Requirements, Architecture and Proof of Concept — Talk to Jesus*. BITS Pilani.
3. Rachakonda, M. (2026). *Study Project Phase 3: Implementation, Validation and Results — Talk to Jesus*. BITS Pilani.
4. Kumar, P. *Study Project — Complete Reference Guide, B.Sc. Computer Science*. BITS Pilani.
5. OpenAI. *Speech to text — Whisper API documentation*. https://platform.openai.com/docs/guides/speech-to-text
6. OpenAI. *Chat Completions API documentation*. https://platform.openai.com/docs/guides/text-generation
7. ElevenLabs. *Text to Speech API documentation*. https://elevenlabs.io/docs
8. Google. *Cloud Run documentation*. https://cloud.google.com/run/docs
9. Google. *Google Identity — verifying an ID token*. https://developers.google.com/identity/sign-in/web/backend-auth
10. Razorpay. *Subscriptions API and webhook signature verification*. https://razorpay.com/docs/api/subscriptions/
11. Supabase. *Row Level Security*. https://supabase.com/docs/guides/auth/row-level-security
12. Flutter. *Flutter documentation*. https://docs.flutter.dev
13. Riverpod. *Riverpod documentation*. https://riverpod.dev
14. Jones, M., Bradley, J. and Sakimura, N. (2015). *RFC 7519: JSON Web Token (JWT)*. IETF. https://www.rfc-editor.org/rfc/rfc7519
15. Krawczyk, H., Bellare, M. and Canetti, R. (1997). *RFC 2104: HMAC — Keyed-Hashing for Message Authentication*. IETF. https://www.rfc-editor.org/rfc/rfc2104
16. Free Use Bible API. *bible.helloao.org* — the third-party scripture API used by the Bible reader. https://bible.helloao.org
17. YouVersion Bible App. https://www.bible.com — surveyed as an existing system in Phase 1.
18. Pray.com. https://www.pray.com — surveyed as an existing system in Phase 1.

# APPENDIX A — USER MANUAL

This appendix is written for someone using the application, not building it. It is also published separately as `07-User-Manual.docx`.

## A.1 Installing and starting

The application is not published to the App Store or Google Play. It is installed from a build supplied directly — an `.apk` on Android, or through TestFlight or a development build on iOS. On first launch it requests no permissions; the microphone is requested later, at the moment it is first needed.

## A.2 Signing in

The login screen shows a single control, **Sign up with Google** (Figure 1). Tap it, choose a Google account, and accept the consent prompt (Figure 2). The application creates an account on first sign-in and takes you to the home screen. There is no password to set or remember.

![Figure 2 — The Google consent prompt shown by iOS on first sign-in.](../figures/fig-02-google-consent.png)

**Demonstration account.** Tapping the headline "God First, Every Day." five times reveals an additional **Enter with Demo Account** button. This exists for demonstrations and does not require a Google account.

## A.3 The home screen

The home screen (Figure 3) has four elements.

- **The menu button**, top left, opens your profile drawer.
- **The language toggle**, top centre, switches between **EN** and **తె**.
- **The status badge**, top right, shows subscription state: a green dot when a subscription is active, a crossed icon when it is not. Tapping the crossed icon opens the subscription options.
- **The voice bar**, along the bottom, is the main control. Above it sit two buttons, **Jesus Songs** and **Bible**.

![Figure 3 — The home screen in English.](../figures/fig-03-home-english.png)

## A.4 Having a conversation

1. Tap the voice bar labelled **Talk to Jesus**.
2. The first time, iOS or Android will ask for microphone permission. Allow it. If you previously denied it, the application offers to open system settings.
3. Recording begins (Figure 6). Speak naturally. There is no time limit, but keep it to a minute or so.
4. Tap the square **stop** button when finished, or the **×** to cancel without sending.
5. The bar shows *Listening to your heart* while the reply is prepared.
6. The reply appears as text and plays aloud automatically.

![Figure 7 — While the reply is being prepared, the bar reads "Listening to your heart".](../figures/fig-07-voice-processing.png)

**Expect to wait.** A reply currently takes around 25 to 30 seconds. This is longer than intended; Section 3.5 of the main report explains why. The application has not frozen.

**Switching language.** Tap **EN | తె**. Every visible label changes immediately and the reply you receive next will be in the selected language (Figure 5). You do not need to restart.

**A note on what you will see.** Replies currently include bracketed words such as `[gently]` or `[prayerfully]`. These are instructions to the voice engine that were not meant to be displayed. They are a known defect (D-01) and do not form part of the message.

## A.5 Conversation history

Open the menu, top left, and choose **Conversation History** (Figure 8). Each card shows the language, how long ago the exchange happened, what you said and what was said in reply. Pull down to refresh. History is private to your account.

## A.6 Reading the Bible

Tap **Bible** on the home screen.

- **Change book or chapter** — tap the book name in the header, search or scroll, then pick a chapter from the grid (Figure 11).
- **Change translation** — tap the translation code in the header. Six are offered, including two in Telugu (Figure 10).
- Your position is remembered per book and translation, so returning takes you back where you were.
- Chapters you have already read remain available without a network.

![Figure 12 — The Bible reader in English, showing John 1.](../figures/fig-12-bible-english.png)

![Figure 11 — The book and chapter selector, with search.](../figures/fig-11-bible-book-chapter.png)

![Figure 10 — The translation selector. Six translations are offered, two of them Telugu.](../figures/fig-10-bible-translations.png)

## A.7 Listening to hymns

Tap **Jesus Songs** (Figure 13). Twelve hymns are bundled with the application and play without a network. Tap one to open the player (Figure 14), which offers play, pause and a seek bar.

**Known limitation.** The previous and next buttons in the player do not currently work (defect D-02). Go back to the list to change track.

![Figure 14 — The hymn player.](../figures/fig-14-audio-player.png)

## A.8 Subscribing

The first three conversations are free. After that the subscription sheet appears (Figure 15).

1. The plan is **₹499 per month** for twelve monthly cycles.
2. Tap it to open Razorpay checkout (Figure 16).
3. Enter a mobile number and email, then choose UPI, card or e-mandate.
4. Complete the payment in your UPI application if prompted.
5. On success you return to the application and the status badge turns green (Figures 17 and 18).

Payments are handled entirely by Razorpay. The application never sees your card or UPI credentials.

## A.9 Signing out

Open the menu and choose **Sign Out**. This clears the stored token from the device. Your conversation history is retained on the server and reappears when you sign back in.

## A.10 Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| The voice bar does nothing | Microphone permission denied | Open system settings and enable the microphone for TalkToJesus |
| Reply takes 30 seconds | Expected behaviour today | Wait. See Section 3.5 of the main report |
| Reply arrives as text with no audio | Speech synthesis unavailable or disabled | The text reply is still correct. Try again later |
| "Subscription required" after three conversations | Free tier exhausted | Subscribe, or wait for an administrator to reset the counter |
| Payment succeeded but the badge is still inactive | Webhook not yet delivered | Reopen the application after a few seconds; a 24-hour grace period covers this window |
| Bible will not load | No network and the chapter is not cached | Connect to a network once; the chapter is then cached |
| Signed out unexpectedly | Token expired or was rejected | Sign in again |
| Hymns will not play | Audio routed elsewhere or device muted | Check the volume and any connected Bluetooth device |

## A.11 Frequently asked questions

**Is this a real person?** No. Replies are generated by a language model under a persona prompt. It is not a substitute for a pastor, a counsellor or a doctor.

**Should I rely on it in a crisis?** No. The persona is instructed to defer to human pastoral care for matters of crisis. Please contact a person you trust or an appropriate professional service.

**Are the scripture citations reliable?** They are generated by the model rather than retrieved from a verified corpus, and their accuracy was not formally verified (Section 3.8). Check any citation that matters to you.

**Who can see my conversations?** They are stored on the project's server and are visible to an administrator through the console. There is currently no retention policy or deletion path — this is a recorded limitation.

**Does it work offline?** The Bible reader and the hymn library do, once cached. Conversation requires a network.

**Can I type instead of speaking?** Not in this build. The capability exists in the API but has no interface.

# APPENDIX B — INSTALLATION GUIDE

Also published separately as `08-Installation-Guide.docx`.

## B.1 Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Node.js | 20 LTS | Production runs Node 20; development has been run on Node 24.7 |
| npm | 10+ | Ships with Node 20 |
| Flutter SDK | 3.38.6 stable | Continuous integration pins this; 3.32.7 has been used locally |
| Xcode | 15+ | iOS builds only |
| Android Studio | Recent | Android builds only |
| Docker | Recent | Container builds only |
| `gcloud` CLI | Recent | Cloud Run deployment only |

Accounts required: Supabase, OpenAI, ElevenLabs, Razorpay, Google Cloud with an OAuth client, and Firebase.

## B.2 Getting the source

```
git clone https://github.com/manish-gitx/rn-final-manish.git
cd rn-final-manish
```

The repository is a monorepo: `TalkToJesus-backend/` is the API, `talktojesus-frontend/` is the Flutter application, and the `Dockerfile` and `cloudbuild.yaml` at the root build and deploy the backend.

## B.3 Provisioning the database

In the Supabase SQL editor, run these three files **in order**:

1. `TalkToJesus-backend/supabase-setup.sql` — creates `users`, `songs`, `plans`, `subscriptions`
2. `TalkToJesus-backend/supabase-admin-setup.sql` — adds `is_admin`, `conversation_logs`, `webhook_events`, `feature_flags`, `admin_audit_log`
3. `TalkToJesus-backend/admin-bootstrap.sql` — idempotent; ends with a verification query

Running them out of order fails, because the second alters a table the first creates.

## B.4 Backend configuration

Create `TalkToJesus-backend/.env`. These are the variable names the code actually reads; note that two of them differ from the names given in the repository README, and the code is authoritative.

| Variable | Required | Notes |
|---|---|---|
| `PORT` | No | Defaults to 4040; the container sets 8080 |
| `NODE_ENV` | No | Selects Razorpay credentials and the plan filter |
| `LOG_LEVEL` | No | Defaults to `info` |
| `SUPABASE_URL` | **Yes** | Module throws at import if absent |
| `SUPABASE_KEY` | **Yes** | Service-tier key. **The README calls this `SUPABASE_SERVICE_ROLE_KEY`; the code reads `SUPABASE_KEY`** |
| `JWT_SECRET` | **Yes** | Module throws at import if absent |
| `GOOGLE_CLIENT_ID_WEB` | Yes (≥1 of 3) | **The README shows a single `GOOGLE_CLIENT_ID`; the code reads three separate variables** |
| `GOOGLE_CLIENT_ID_IOS` | Yes (≥1 of 3) | |
| `GOOGLE_CLIENT_ID_ANDROID` | Yes (≥1 of 3) | |
| `RAZORPAY_KEY_ID_DEV` / `_SECRET_DEV` / `_WEBHOOK_SECRET_DEV` | **Yes** when not production | Module throws at import if absent |
| `RAZORPAY_KEY_ID_PROD` / `_SECRET_PROD` / `_WEBHOOK_SECRET_PROD` | **Yes** in production | |
| `OPENAI_API_KEY` | **Yes** | Used for both transcription and generation |
| `OPENAI_MODEL` | No | Defaults to `gpt-4o` |
| `OPENAI_MAX_TOKENS` | No | Defaults to 800 |
| `OPENAI_TEMPERATURE` | No | Defaults to 0.7 |
| `ELEVENLABS_API_KEY` | No | If absent, replies are text-only rather than failing |
| `ELEVENLABS_VOICE_ID` | Yes for speech | |
| `ELEVENLABS_MODEL` | No | Defaults to `eleven_multilingual_v2` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Yes for the console | Console login returns 500 if unset |

There is no `.env.example` in the repository; this table serves that purpose.

**A note on ports.** Three different ports appear across the project's documentation — 3000, 4040 and 5000. The code defaults to **4040** and the container listens on **8080**. Use those.

## B.5 Running the backend

```
cd TalkToJesus-backend
npm ci
npm run dev          # nodemon on port 4040
```

Verify with `curl http://localhost:4040/`, which returns a JSON health banner. The administrative console is then at `http://localhost:4040/admin`.

Other commands:

```
npm run build        # tsc, also the CI typecheck gate
npm start            # node dist/index.js
npm test             # 66 tests, no credentials required
npm run seed:demo    # ~200 synthetic conversations across 30 days
npm run seed:demo:clear
```

`npm run seed:demo` writes clearly-marked demonstration rows: addresses end `@demo.talktojesus.local` and seeded replies carry a marker. It is demonstration data, not traffic.

## B.6 Client configuration

Three files are required and are deliberately not in source control:

- `talktojesus-frontend/android/app/google-services.json`
- `talktojesus-frontend/ios/Runner/GoogleService-Info.plist`
- `talktojesus-frontend/lib/firebase_options.dart` — generated by `flutterfire configure`

For a release Android build you also need `android/key.properties` and a keystore; without them the build falls back to unsigned.

## B.7 Running the client

```
cd talktojesus-frontend
flutter pub get
flutter run                                                    # against the deployed backend
flutter run --dart-define=API_BASE_URL=http://localhost:4040   # against a local backend
```

`API_BASE_URL` is the only compile-time define that takes effect. The others named in `EnvironmentConfig` are inert, because `main.dart` initialises the flavour with literal values instead of reading them.

## B.8 Building for release

```
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

Before submitting to Google Play, change the application identifier from the scaffold default `com.example.talktojesus` (defect D-09).

## B.9 Container build and deployment

From the repository root — the Dockerfile expects root as its build context:

```
docker build -t talktojesus-backend .
docker run -p 8080:8080 --env-file TalkToJesus-backend/.env talktojesus-backend
```

Deployment is Cloud Build to Artifact Registry to Cloud Run, service `talktojesus-backend` in `us-central1`. Note the caveat in Section 4.2.2: the live trigger currently carries its configuration inline and ignores the checked-in `cloudbuild.yaml`.

## B.10 Administrative access

The console at `/admin` accepts the `ADMIN_EMAIL` and `ADMIN_PASSWORD` pair and issues a token carrying a console-administrator claim. That principal is synthetic — it has no row in `users`. The consequence is that there is no `is_admin` flag to clear, so **rotating the password is the only revocation, and tokens already issued remain valid until they expire.**

To grant in-application administrative access to a real user instead, set `is_admin = true` on their `users` row.

## B.11 Troubleshooting

| Symptom | Cause | Resolution |
|---|---|---|
| Backend exits at startup | A required variable is missing | Check `SUPABASE_URL`, `SUPABASE_KEY`, `JWT_SECRET` and the Razorpay set |
| 503 with `SCHEMA_NOT_PROVISIONED` | Admin migration not run | Run `supabase-admin-setup.sql` |
| Every login fails | No Google client ID configured | Set at least one of the three |
| `/admin` returns 404 as an admin | The admin gate returns 404 by design | Confirm `is_admin` is exactly `true`, or use the console credentials |
| Console login returns 500 | `ADMIN_EMAIL` / `ADMIN_PASSWORD` unset | Set both and restart |
| Replies have no audio | ElevenLabs key missing, quota exhausted, or `tts_enabled` false | Check the key and the flag |
| Client cannot reach a local backend | Device cannot resolve `localhost` | Use the host's LAN address in `API_BASE_URL` |
| Payment succeeds, app still locked | Webhook not delivered | Check the webhook secret and the console's webhook tab |

# APPENDIX C — SOURCE CODE

Repository: **https://github.com/manish-gitx/rn-final-manish**

Branch `main`. The submitted revision is `ccfb64b`.

| Path | Contents |
|---|---|
| `TalkToJesus-backend/src/api/routes/` | 28 endpoint definitions |
| `TalkToJesus-backend/src/api/controllers/` | Request handling, validation, response shaping |
| `TalkToJesus-backend/src/api/services/` | Business logic and all external calls |
| `TalkToJesus-backend/src/api/middlewares/` | Authentication and the administrative gate |
| `TalkToJesus-backend/src/config/prompts.ts` | The persona prompt, parameterised by language |
| `TalkToJesus-backend/src/__tests__/` | 66 Jest cases across 10 suites |
| `TalkToJesus-backend/public/admin/index.html` | The administrative console, one file |
| `TalkToJesus-backend/*.sql` | Schema provisioning, in the order given in Appendix B.3 |
| `talktojesus-frontend/lib/presentation/pages/` | The eight screens |
| `talktojesus-frontend/lib/data/services/` | API client, authentication, token storage, conversation, payment |
| `talktojesus-frontend/test/` | 75 Flutter cases across 9 files |
| `docs/figures/` | The 29 report figures with an index |
| `docs/evidence/` | Captured test output and the extracted case list |
| `scripts/docs/` | The scripts that generate the figures and the test tables |
| `Dockerfile`, `cloudbuild.yaml`, `.github/workflows/ci.yml` | Build, deployment and continuous integration |

# APPENDIX D — DEMONSTRATION VIDEO

| Recording | Duration | Link |
|---|---|---|
| Application demonstration | 3 min 50 s | https://drive.google.com/file/d/124faeA_zm2HM7rPP_rWwJPsXSj6iN4QS/view |
| Administrative console | 1 min 13 s | https://drive.google.com/file/d/1UeTyKBB8uDYdNhWjS14s2lbwYxO7xW6p/view |

Both links are publicly readable. The figures in this report were sampled from these recordings; `docs/figures/FIGURES.md` maps each figure to its source and timestamp.

# APPENDIX E — THIRD-PARTY COMPONENTS AND LICENSING

This appendix supports the plagiarism and originality declaration, which is published separately as `06-Plagiarism-Compliance.docx`.

## E.1 What is original

All application source code in `TalkToJesus-backend/src/`, `talktojesus-frontend/lib/` and `talktojesus-frontend/test/`, the database schema, the persona prompt, the administrative console, the continuous integration and deployment configuration, and this report were written by the candidate. No code was copied from another project.

## E.2 Backend dependencies

Licences below were read from each package's own metadata in `node_modules`, not assumed.

| Package | Licence | Package | Licence |
|---|---|---|---|
| `@supabase/supabase-js` | MIT | `morgan` | MIT |
| `axios` | MIT | `multer` | MIT |
| `cors` | MIT | `razorpay` | MIT |
| `dotenv` | BSD-2-Clause | `winston` | MIT |
| `express` | MIT | `zod` | MIT |
| `form-data` | MIT | `jest` | MIT |
| `google-auth-library` | Apache-2.0 | `ts-jest` | MIT |
| `jsonwebtoken` | MIT | `typescript` | Apache-2.0 |
| | | `nodemon`, `ts-node`, `ts-node-dev`, all `@types/*` | MIT |

## E.3 Client dependencies

Licences below were read from each package's `LICENSE` file in the pub cache.

| Package | Licence | Package | Licence |
|---|---|---|---|
| `flutter_riverpod` | MIT | `google_sign_in` | BSD-3-Clause |
| `flutter_svg` | MIT | `http` | BSD-3-Clause |
| `audioplayers` | MIT | `path`, `path_provider` | BSD-3-Clause |
| `permission_handler` | MIT | `shared_preferences` | BSD-3-Clause |
| `razorpay_flutter` | MIT | `sqflite` | BSD-3-Clause |
| `posthog_flutter` | MIT | `record` | BSD-3-Clause |
| `sentry_flutter` | MIT | `connectivity_plus` | BSD-3-Clause |
| `in_app_review` | MIT | `crypto` | BSD-3-Clause |
| `lottie` | MIT | `google_fonts` | BSD-3-Clause |
| `cupertino_icons` | MIT | `shimmer` | BSD-3-Clause |
| `flutter_launcher_icons` | MIT | `url_launcher` | BSD-3-Clause |
| | | `firebase_core`, `firebase_auth`, `cloud_firestore` | BSD-3-Clause |

Typefaces Poppins and Lora are fetched at runtime by `google_fonts` and are licensed under the SIL Open Font License.

## E.4 External services

| Service | Role | Terms |
|---|---|---|
| OpenAI (Whisper, GPT-4o) | Transcription and generation | Commercial API, per-use |
| ElevenLabs | Speech synthesis | Commercial API, per-use |
| Google Identity | Authentication | Google API terms |
| Razorpay | Payments | Commercial agreement |
| Supabase | Managed PostgreSQL | Commercial |
| Google Cloud Run | Hosting | Commercial |
| **bible.helloao.org** | **Scripture text for the Bible reader** | **Free public API — third-party, not operated by this project** |

The Bible reader's content comes entirely from a third-party public API. No scripture text is authored or hosted by this project.

## E.5 Bundled media

Twelve hymn excerpts, approximately forty-two seconds each at 64 kbps mono, sourced from Wikimedia Commons and the Internet Archive. Each was trimmed, given a fade, and loudness-normalised; no other alteration was made. Nine are public domain. **Three are CC BY-SA and carry a continuing obligation:**

| Track | Licence |
|---|---|
| What a Friend We Have in Jesus | CC BY-SA 4.0 |
| Holy, Holy, Holy | CC BY-SA 4.0 |
| Abide With Me | CC BY-SA 3.0 |

CC BY-SA requires attribution and share-alike on redistribution. The full record, with source links per track, is kept alongside the assets at `talktojesus-frontend/assets/music/hymns/ATTRIBUTION.md`, which itself states that the credits should be surfaced in an about screen.

**The application has no about screen. This obligation is therefore currently unmet**, and is recorded as defect D-08 with the remedy listed in Section 6.4.

Album artwork is twelve public-domain paintings from the Metropolitan Museum of Art Open Access collection (CC0), centre-cropped and downscaled. Artists include Gerard David, Hans Memling, Eugène Delacroix, Petrus Christus, Ambrosius Benson, Sebastiano Ricci and Joos van Wassenhove; the per-track record is in the same attribution file.

## E.6 Prior work by the candidate

This report restates material from the candidate's own Phase 1, Phase 2 and Phase 3 submissions — the abstract, the objectives, the literature survey and the requirement definitions in particular. Those documents are cited as references 1 to 3. Section 1.6 and Section 3.6 record every point at which this report corrects or supersedes them.

## E.7 Similarity check

_To be completed by the candidate._ The institutional similarity check has not been run from within this project. Reported similarity is expected to be concentrated in the restated requirement definitions and objectives, which are the candidate's own prior submissions and are cited as such.

Similarity score: ____________  Tool: ____________  Date: ____________
