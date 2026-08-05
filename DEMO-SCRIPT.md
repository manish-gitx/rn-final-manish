# Talk to Jesus — 15-Minute Demo Script

Capstone demo against the **Capstone_Project_15_Min_Demo_Template** (10 slides).
Presenter: Manish Rachakonda (2023EBCS668) · Advisor: Swapnil Saurav · B.Sc. CS, BITS Pilani Digital

> **The one rule:** slides 1–6 are five minutes total. They are context, not content.
> The demo is what gets scored. If you are at slide 6 and the clock says 6:00, skip
> slide 6 entirely and start the demo.

---

## 1. Timing at a glance

| # | Slide | Length | Ends at |
|---|-------|--------|---------|
| 1 | Title | 0:20 | 0:20 |
| 2 | Problem Statement | 1:10 | 1:30 |
| 3 | Objectives & Scope | 0:50 | 2:20 |
| 4 | Existing System / Literature | 0:50 | 3:10 |
| 5 | Proposed Architecture | 1:20 | 4:30 |
| 6 | Tools & Technologies | 0:30 | 5:00 |
| 7 | **Implementation / LIVE DEMO** | **7:00** | **12:00** |
| 8 | Results & Analysis | 1:15 | 13:15 |
| 9 | Challenges & Limitations | 0:45 | 14:00 |
| 10 | Conclusion & Future Work | 0:45 | 14:45 |
| — | Handoff to Q&A | 0:15 | 15:00 |

Put a silent timer on your laptop. Check it at slide 7 (must be ≤ 5:00) and at the
end of the demo (must be ≤ 12:00).

---

## 2. Pre-flight checklist

### The day before

Deployment is automatic: a Cloud Build trigger watches `main` on
`manish-gitx/rn-final-manish`, builds the root `Dockerfile`, and updates Cloud Run.
**Pushing to main is the deploy.** Do it early enough to fix a failed build.

- [ ] `supabase-admin-setup.sql` has been run in Supabase
- [ ] `UPDATE users SET is_admin = true WHERE email = '<your email>';`
- [ ] Push to `main`, then confirm the build went green in Cloud Build
- [ ] **Set `ADMIN_EMAIL` / `ADMIN_PASSWORD` on the Cloud Run service** — they are not
      there yet, and without them `/api/admin/login` returns 500
- [ ] `curl <url>/admin` returns 200 (proves the Dockerfile `COPY public` line worked)
- [ ] `npm run seed:demo` — dashboard must not be empty
- [ ] `npm test` → 62 passing · `flutter test` → 75 passing (screenshot both for slide 8)
- [ ] Record fallback clips: Google login, Razorpay payment, one full voice turn
- [ ] Full rehearsal, timed, twice

> **Do not change `NODE_ENV` on Cloud Run.** It is deliberately not `production`, which
> is what selects the Razorpay **test** keys and the dev plan. Only `RAZORPAY_*_DEV`
> secrets are configured — flipping to `production` makes `utils/razorpay.ts` throw at
> import and the container will fail to start.

### 30 minutes before

- [ ] Phone charged > 80%, screen mirroring tested on the actual projector
- [ ] Phone on **Do Not Disturb**, brightness at max, auto-lock off
- [ ] Backend warmed up — measured cold start is **4.4s**, warm is **~0.4s**. Either hit
      the URL a few times, or set `--min-instances=1` beforehand and drop it back after
- [ ] Admin console open and signed in on the laptop
- [ ] App signed in, conversation count reset to 0 (admin console → Users → *Reset free tier*)
- [ ] Fallback video open in a background tab
- [ ] Wifi tested on the venue network, not just your hotspot

### 2 minutes before

- [ ] Screen layout: **phone mirrored left, admin console right**, both visible
- [ ] Slides in presenter mode on the second display
- [ ] Timer started

---

## 3. Slide-by-slide talk track

### Slide 1 — Title (0:20)

> "Talk to Jesus — a spiritual companion mobile application. I'm Manish Rachakonda,
> 2023EBCS668, under the guidance of Swapnil Saurav."

Do not read the slide. Move on.

### Slide 2 — Problem Statement (1:10)

Open with the number:

> "Telugu Bible apps have millions of downloads — and zero conversation."

Then the four gaps:

1. **One-way communication** — existing apps deliver content; you cannot ask them anything.
2. **Limited accessibility** — a pastor means a visit, an appointment, and the nerve to ask.
3. **No context-awareness** — people read scripture but struggle to apply it to their own situation.
4. **Language barrier** — AI spiritual guidance in regional languages barely exists.

> "So the question I started with was: what if those millions of readers could
> actually *talk* to something that answers from scripture, in their own language?"

### Slide 3 — Objectives & Scope (0:50)

Seven primary objectives (PO1–PO7). Do not read all seven — group them:

> "Seven objectives, in three groups: build the cross-platform app and the AI voice
> pipeline; make it genuinely bilingual, English and Telugu; and make it a real
> product — payments, cloud deployment, monitoring."

**In scope:** app, backend, AI conversation, bilingual, Bible, music, subscriptions, cloud.
**Out of scope:** more than two languages, 3D avatar, community features, offline AI, store publication.

### Slide 4 — Existing System / Literature (0:50)

Show the five-row comparison table (Phase 1 §5): YouVersion, Telugu Bible apps,
Pray.com, ChatGPT, Glorify/Abide.

> "Every one of these is either static content or a general-purpose AI. Not one is
> conversational, scripture-grounded, *and* available in a regional language. That
> empty column is the project."

### Slide 5 — Proposed Architecture (1:20)

Three-tier diagram. **Make sure the admin console appears as a second client** on
the presentation tier — that is what earns it a place in the demo.

> "Presentation tier: the Flutter app, and a web admin console. Application tier:
> Node and Express on Google Cloud Run, auto-scaling from zero. Data tier: Supabase
> Postgres, plus OpenAI, ElevenLabs and Razorpay."

The one design point worth stating:

> "The API is completely stateless — every request carries its own JWT. That is what
> lets Cloud Run scale to zero and back without any shared session state."

### Slide 6 — Tools & Technologies (0:30)

Do not read the stack table. One sentence:

> "Nineteen technologies across mobile, backend, AI, payments, cloud and observability.
> Flutter, Node and TypeScript, Supabase, GPT-4o, Whisper, ElevenLabs, Razorpay,
> Cloud Run, Sentry and PostHog. Everything on the slide."

**→ Switch to the live demo now.**

---

## 4. The demo (7:00) — Slide 7

Phone on the left, admin console on the right, both on screen the whole time.

| # | Time | Do | Say |
|---|------|-----|-----|
| 1 | 0:30 | Google sign-in | "Google OAuth, backend mints a JWT. Stateless — that's what lets Cloud Run scale to zero." |
| 2 | 0:50 | Voice: *"I feel anxious about my exams."* | "Record, Whisper transcribes, GPT-4o answers from scripture, ElevenLabs speaks it back." **Point right:** "That counter just moved. Live." |
| 3 | 0:40 | Voice: *"What should I pray?"* — no context given | "I never said what about. It remembered. Multi-turn context — this is a companion, not a search box." |
| 4 | 0:50 | Toggle EN → TE, ask in Telugu | "Same pipeline. Language-specific system prompt, culturally appropriate address — *na bidda*, my child. And the whole interface switched, not just the reply." |
| 5 | 0:25 | Sidebar → Conversation History | "Every session is persisted and reviewable." |
| 6 | 0:40 | Bible → pick a book → back → same book again | "First load hits the external API. Second is under 100ms from local SQLite. 66 books, 6 translations including Telugu." |
| 7 | 0:25 | Jesus Songs → play → seek | Keep it short. Play, seek, out. |
| 8 | 0:25 | 4th conversation | "Free tier is three conversations. Fourth returns a 402 and the app opens the subscription sheet." |
| 9 | 0:40 | Razorpay sheet, ₹499/month | "Razorpay test mode. Full subscription lifecycle — eight webhook events, HMAC-verified." |
| 10 | **1:15** | **Admin console** | See below. |
| 11 | 0:20 | Buffer | Absorbs the overruns. There will be overruns. |

### Beat 10 — the admin walkthrough (the part that separates you)

Move top to bottom, roughly ten seconds each:

1. **Stat cards** — "Users, conversations, active subscriptions, monthly recurring revenue, free-to-paid conversion."
2. **Conversations per day** — "Thirty-day trend."
3. **Language split** — "English versus Telugu. Bilingual isn't a checkbox on a slide, it's a third of actual usage."
4. **Latency breakdown** — the important one:
   > "This is where the three to six seconds actually goes: speech-to-text, the model, then speech synthesis, p50 and p95 for each. The model is the biggest slice, which is exactly why streaming the response is the first optimisation in the Capstone."
5. **Webhooks tab** — "Every Razorpay event, with whether its HMAC signature verified. The rejected ones are logged too — that's the evidence the check is actually running."
6. **The finale — Songs tab:** add a song → switch to the phone → pull to refresh → it appears.
   > "Admin writes to Postgres, the app reads it back. Both tiers, live, right now."

> **Be honest about the data.** If asked: "The historical rows are seeded demo data
> so the charts have shape — everything from the last ten minutes is real, and you
> just watched it get written."

### Fallbacks — decide these now, not on stage

| If this fails | Do this |
|---|---|
| Google sign-in stalls | Tap the login title **5 times** → "Enter with Demo Account" (hardcoded tester JWT, no Google round-trip) |
| Voice pipeline slow or noisy room | Switch to text input — same pipeline minus Whisper, roughly 2s instead of 5s |
| Razorpay sheet won't open | Play the recorded clip. Say "test mode, recorded earlier" and keep moving |
| Backend cold start | Keep talking through it; mention it deliberately as a Cloud Run scale-to-zero tradeoff |
| Venue wifi dies completely | Play the full recorded walkthrough and narrate over it |

Never apologise twice for the same problem. State it once, move on.

---

## 5. Slide 8 — Results & Analysis (1:15)

Screenshot the admin console. Real numbers beat bullet points.

**Say these numbers out loud:**

- All **20 functional requirements** (FR1–FR20) implemented and validated
- **62 backend tests and 75 frontend tests — all passing**
- Voice pipeline **3–6 seconds** end to end; text path roughly **2 seconds**
- Bible cache hit **under 100ms**, against 1–2s for the first network load
- Backend deployed on **Cloud Run, us-central1**, auto-scaling from zero
- Razorpay HMAC verification **rejected 100%** of tampered payloads in testing

> "The number I'd point at is the latency breakdown. Most student projects can tell
> you their app works. This one can tell you exactly where its seconds go."

## 6. Slide 9 — Challenges & Limitations (0:45)

Be specific and be honest — the Study Guide says clarity here is viewed positively,
and volunteering a weakness is much stronger than being caught by it.

- **Voice latency** — three sequential external API calls. 3–6s. Streaming is the fix, and it's Capstone scope.
- **Cold starts** — scale-to-zero costs about **4.4s** on the first request; warm requests are **~0.4s**. Minimum instances fixes it, at the cost of paying for an always-on container.
- **Telugu transcription** — accuracy drops with background noise more than English does.
- **API quotas** — ElevenLabs character limits shaped how much load testing was possible.
- **Stored transcripts** — conversation logging is new, and it is personal data. Retention and redaction policy is required work, not optional.

## 7. Slide 10 — Conclusion & Future Work (0:45)

> "Study Project to production-ready system in two months: deployed backend,
> bilingual voice AI, payments, and the operational tooling to see what it's doing."

**Capstone roadmap:** streaming responses to cut perceived latency · guided prayer mode ·
devotional plans · push notifications · more regional languages · full accessibility ·
Play Store publication.

> "Same problem statement, more depth. Thank you — happy to take questions."

---

## 8. Q&A prep

**"Isn't this just a ChatGPT wrapper?"**
> Three differences: it's voice-to-voice, not text; it's grounded in a scripture-specific
> system prompt with cultural addressing; and it works in Telugu, which general tools
> handle poorly. Plus the whole product layer — free tier, subscriptions, offline Bible cache.

**"How do you know the theology is right?"**
> I don't guarantee it, and I say so. The system prompt enforces scripture grounding,
> and Telugu responses were reviewed by native speakers. It's a companion for reflection,
> not a replacement for a pastor. A denominational review process is Capstone work.

**"Why is it so slow?"**
> Three sequential API calls — you can see the split on the dashboard. GPT-4o is the
> largest slice. Streaming its response into TTS sentence by sentence would cut
> *perceived* latency by roughly half, and that's the first Capstone optimisation.

**"What happens if OpenAI goes down?"**
> Today the conversation fails with a handled error and the app stays stable. The service
> modules are already an abstraction layer, so swapping providers is a config change, not
> a rewrite. Proper fallback chaining is future work.

**"Is the admin console secure?"**
> It requires a valid JWT *and* `is_admin` on the user row, checked against the database
> on every request rather than trusted from the token — so revoking access is immediate.
> Non-admins get a 404, not a 403, so the surface isn't confirmed to them. Being fully
> honest: CORS is still wide open and there's a long-lived test token in the repo. Both
> are on my list.

**"Show me your CI/CD."**
> A Cloud Build trigger watches the `main` branch. Every push builds the Dockerfile,
> pushes the image to Artifact Registry tagged with the commit SHA, and updates the
> Cloud Run service. The running revision is traceable back to an exact commit — the
> current one is tagged `84c6660`. The trigger holds the build config inline, so
> there's no `cloudbuild.yaml` in the repo any more; my Phase 2 and 3 documents still
> name that file and I should correct them.

**"Why Supabase over Firebase?"**
> Relational data — users, plans, subscriptions with real foreign keys and joins.
> Subscription state is inherently relational, and I wanted SQL for the analytics.

**"How much does it cost to run?"**
> Everything sits in free tiers today. At scale the driver is per-conversation API cost,
> which is why the free tier is capped at three conversations — that cap is a runtime
> feature flag I can change from the admin console without redeploying.

**"Why did two tests fail in your Phase 3 report?"**
> They failed, and the report's stated cause was wrong. The real problem was in the test
> mock — it only made `.single()` awaitable while the code awaits the query builder
> directly. Every "expect false" case was passing for the wrong reason. It's fixed;
> the suite is 62 of 62.

---

## 9. Numbers cheat sheet

| | |
|---|---|
| Functional requirements | 20 (FR1–FR20), all implemented |
| Primary objectives | 7 (PO1–PO7) |
| Backend tests | 62 passing, 9 suites |
| Frontend tests | 75 passing |
| Technologies | 19 |
| Bible books / translations | 66 / 6 (incl. Telugu) |
| Free tier | 3 conversations |
| Subscription | ₹499/month, 12 cycles |
| Webhook events handled | 8 |
| Voice pipeline | 3–6s (text path ≈ 2s) |
| Bible cache hit | < 100ms |
| Deployment | Cloud Run, us-central1, maxScale 3, minScale 0 |
| Cold start / warm | 4.4s / ~0.4s (measured) |
| CI/CD | Cloud Build trigger on push to `main` → Docker build → Artifact Registry → Cloud Run |
| Languages | English, Telugu |

---

## 10. Delivery reminders

- **Do not read slides.** The panel can read faster than you can talk.
- **Face the panel, not the screen.** You know what's on it.
- **Silence is fine** while something loads. Narrate what's happening instead of filling air.
- **Volunteer one limitation before you're asked.** It buys credibility for everything else.
- **Stop at 14:45.** Ending early is confident; being cut off is not.
