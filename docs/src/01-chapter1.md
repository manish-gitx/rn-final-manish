# CHAPTER 1: INTRODUCTION

The problem, the requirements and the system design were settled across the three Study Project phases. What follows is a condensed restatement of that work. Where building the system forced a departure from it, Section 1.6 sets out the departure and why it happened.

## 1.1 Overview of the project

TalkToJesus is a mobile application that lets a believer speak a question aloud and receive a spoken reply grounded in scripture. The user holds the phone, presses a single control, says what is on their mind in English or Telugu, and hears a response in a synthesised voice a few moments later. The reply is written in the first person, addresses the user as "My child" in English or "నా బిడ్డ" in Telugu, cites scripture by book, chapter and verse, and closes with a short prayer.

Around that central interaction the application provides a bilingual Bible reader with six translations including two in Telugu, a library of twelve public-domain hymns, a transcript of the user's previous conversations, and a subscription that lifts a three-conversation free-tier limit.

The system is not a single application. It comprises a Flutter client for iOS and Android, a TypeScript REST API running on Google Cloud Run, a PostgreSQL database provisioned through Supabase, an administrative console served as static files by the same API, and integrations with four external services: Google for identity, OpenAI for transcription and generation, ElevenLabs for speech synthesis, and Razorpay for payments.

## 1.2 Problem statement and motivation

Telugu-language Bible applications have accumulated millions of downloads. They are well made and widely used, and they share one characteristic: the content flows in one direction. A user can read a passage, follow a reading plan or play a recorded song, but cannot ask what a passage means for a decision they are facing on a particular evening.

Four gaps follow from that.

**Communication is one-way.** Existing applications present content. None accept a question and produce an answer specific to it.

**Access to pastoral conversation is limited.** Speaking to a pastor or elder requires that another person be available, that the conversation be scheduled, and that the person seeking guidance be willing to raise the subject with someone they know. For a question asked at two in the morning, or one the user is embarrassed to voice aloud to an acquaintance, none of those conditions hold.

**Guidance is not context-aware.** A reading plan does not know what the reader is worried about. A search returns passages containing a keyword, not passages that address a situation.

**Language and culture are a barrier.** General-purpose conversational assistants can hold a dialogue, but they are not grounded in scripture, they do not adopt a pastoral register, and their Telugu is not idiomatic in a devotional context. Addressing a believer correctly in Telugu is not a translation problem; "నా బిడ్డ" carries a weight that a literal rendering of "my child" does not.

The motivation for the project is the conjunction of these four. Each is individually addressed somewhere in the market. None of the existing systems addresses all four at once, and the combination is what a Telugu-speaking believer with a question at an inconvenient hour actually needs.

## 1.3 Objectives of the capstone

The Study Project defined seven primary and four secondary objectives. They are restated here because Chapter 6 assesses the implementation against them.

**Primary objectives**

**PO1.** Build a cross-platform mobile application providing AI-driven spiritual conversation grounded in biblical teaching.

**PO2.** Build a backend API with secure authentication, conversation management and subscription handling.

**PO3.** Integrate a large language model to produce context-aware, scripture-based responses that adapt to the selected language.

**PO4.** Provide voice interaction through speech-to-text input and text-to-speech output.

**PO5.** Support bilingual operation in English and Telugu with dynamic switching and culturally appropriate responses.

**PO6.** Integrate a payment gateway for subscription monetisation with a free tier and premium plans.

**PO7.** Deploy the backend on Google Cloud Platform using containerisation for automatic scaling.

**Secondary objectives**

**SO1.** Instrument the application with product analytics and error tracking.

**SO2.** Provide a curated library of spiritual music.

**SO3.** Support offline use through local caching and connectivity monitoring.

**SO4.** Provide Bible reading with book, chapter and verse navigation.

## 1.4 Scope of implementation

**In scope, and delivered.** Google sign-in; the voice conversation pipeline in both languages; the bilingual Bible reader with six translations and an offline cache; the bundled hymn library and player; Razorpay subscriptions with webhook reconciliation; the conversation transcript; the administrative console with live metrics, content management, webhook audit, runtime feature flags and an audit trail; deployment to Cloud Run with a continuous integration pipeline.

**In scope, delivered differently than designed.** Multi-turn context was designed as a Capstone extension and was implemented; Section 1.6 records this. Text input to the conversation exists as a working API endpoint but has no user interface in the shipped build.

**Out of scope.** Publication to the App Store and Google Play. A video or animated avatar. Any form of community, sharing or social feature. Human pastoral escalation. Retrieval-augmented generation over a scripture corpus — the system supplies context by replaying previous conversational turns, not by retrieving passages from an indexed corpus, and Section 2.4.4 states this precisely because the distinction is easy to overstate.

## 1.5 Organization of the report

The remainder of this report is arranged as follows. Chapter 2 sets out how the system is built — its architecture, the technologies chosen and why, the individual modules, and the handful of algorithms that carry the real complexity. Chapter 3 is the evidence chapter: how the system was tested, what the measurements showed, which defects were found, and — equally important — which properties were never verified at all. Chapter 4 deals with running and deploying the system. Chapter 5 collects the record of how the work was actually carried out. Chapter 6 draws conclusions and sets out what should be done next. Five appendices follow: a user manual, an installation guide, a source code reference, the demonstration video links, and the third-party licensing record.

## 1.6 Changes from the Study Project design

Implementation departed from the Phase 2 and Phase 3 documents in the following ways. These are recorded here rather than left implicit, because several of them contradict statements in documents that have already been submitted.

**The mobile framework is Flutter, not React Native.** The repository is named `rn-final-manish`, which invites the opposite conclusion. It contains no React Native code. The client is Flutter 3.38.6 with Dart, using Riverpod for state management. The repository name is a historical artefact of an early decision that was reversed before any code was written.

**Multi-turn context was implemented, not deferred.** Phase 3 lists both conversation history and multi-turn context as Capstone future work. Both shipped. The conversation controller loads the previous six turns from the database and replays them into the model's message array; the window size and whether the feature is active at all are runtime flags.

**An administrative console was added.** No phase document mentions it. It comprises eighteen API routes and a single-file web console with six tabs, and it is the source of every measurement in Chapter 3.

**Runtime feature flags were added.** Five flags — the free-tier limit, maintenance mode, speech synthesis, multi-turn context and the context window size — are stored in the database and read on every conversational turn behind a fifteen-second cache. None of this was in the Phase 2 design.

**A webhook audit trail was added.** Every Razorpay webhook is recorded with the result of its signature check, including the ones that fail. Recording failures deliberately preserves the evidence that verification runs at all.

**Continuous integration was added.** A GitHub Actions workflow builds and tests both tiers and verifies the container image on every push to `main`.

**The measured pipeline latency is an order of magnitude worse than reported.** Phase 3 and the presentation deck state a three-to-six second pipeline. The live instance measures 27,457 ms at the median. Section 3.5 establishes where the three-to-six second figure came from and why it is not a measurement. This is the single most important correction in this report.

**The automated test counts in Phase 3 are wrong.** Phase 3 reports 40 backend tests with two failing and 65 frontend tests. The current figures are 66 backend and 75 frontend, none failing. The two failures were fixed, and Phase 3's stated root cause for them was itself incorrect; Section 3.6 gives the actual cause.

**Cold start is 4.4 seconds, not two.** Phase 3 estimates roughly two seconds for a Cloud Run cold start. The measured figure recorded in the demonstration script is 4.4 seconds cold against approximately 0.4 seconds warm.
