# COVER PAGE

Project Title: TalkToJesus — A Bilingual Voice-First AI Spiritual Companion

Student Name & Roll Number: Manish Rachakonda (2023EBCS668)

Program: BSc Computer Science (Online Mode)

Institution: Birla Institute of Technology and Science, Pilani (BITS Pilani)

Academic Year: 2025–2026

Internal Supervisor: Swapnil Saurav

Contact: 2023ebcs668@online.bits-pilani.ac.in

Source code: https://github.com/manish-gitx/rn-final-manish

Date: **25 August 2026**

# DECLARATION

I hereby declare that this capstone project titled "TalkToJesus — A Bilingual Voice-First AI Spiritual Companion" is an original work carried out by me and has not been submitted to any other university or institution for the award of any degree or diploma. All external libraries, services, media assets and reference material used in the project are acknowledged in the References section and in Appendix E, and all third-party licence obligations are recorded there.

Where this report restates conclusions from the Study Project Phase 1, Phase 2 and Phase 3 documents, those documents are cited as prior work of my own. Section 1.6 records every place where the implementation departed from that earlier design, and Chapter 3 records every place where a measurement contradicts a figure quoted in those earlier documents.

Name: **Manish Rachakonda**

Roll Number: **2023EBCS668**

Signature: **Manish Rachakonda**    Date: **25 August 2026**

**Supervisor's approval**

Certified that the work described in this report was carried out by the candidate under my supervision.

Supervisor: Swapnil Saurav

Signature: **Swapnil Saurav**    Date: **25 August 2026**

# ABSTRACT

Bible applications in Telugu have been downloaded by millions of users, yet they present static content — scripture, devotionals and recorded songs — and offer no way to ask a question and receive an answer. General-purpose conversational assistants can hold a dialogue but are neither grounded in scripture nor available in Telugu with culturally appropriate forms of address. This project delivers TalkToJesus, a mobile application in which a user speaks aloud in English or Telugu and receives a spoken, scripture-grounded reply in a first-person pastoral voice.

The system consists of a Flutter mobile application for iOS and Android, a 28-endpoint Express and TypeScript API deployed to Google Cloud Run, a PostgreSQL database provisioned through Supabase across eight tables, and a dependency-free administrative console served by the same API. A conversational turn is a three-stage pipeline: OpenAI Whisper transcribes the recording, OpenAI GPT-4o generates a reply under a language-specific persona prompt with the previous turns supplied as context, and ElevenLabs synthesises that reply as speech. Subscriptions are handled through Razorpay with HMAC-SHA256 webhook verification, and five runtime feature flags allow the free-tier limit, maintenance mode, speech synthesis and the context window to be changed without redeployment.

The engineering contribution that distinguishes this system from a wrapper around a language model is that every turn is instrumented. Each conversation record stores the duration of transcription, generation and synthesis separately alongside the total, so the cost of each stage is a measured quantity rather than an assumption. Because the text-input path skips transcription and records a zero, the price of speech recognition is directly observable in the same table.

Validation used 141 automated tests — 66 backend cases across 10 Jest suites and 75 Flutter cases across 9 files — all passing, together with a functional walkthrough of the complete subscription and conversation flow on physical hardware. The instrumentation produced the project's most consequential result and also contradicted its own earlier documentation: against a non-functional requirement of five seconds, the measured end-to-end latency on the live instance was 27,457 ms at the median, of which speech synthesis alone accounted for 19,618 ms. The three-to-six second figure quoted in the Phase 3 document and in the presentation deck is traceable to the administrative console's demonstration fixtures and is not a measurement. That requirement is therefore recorded as not met, and Section 3.5 sets out what the measurement implies for the design.

Keywords: voice interface, speech recognition, speech synthesis, large language models, bilingual interfaces, Telugu, Flutter, latency instrumentation

# TABLE OF CONTENTS

# LIST OF FIGURES

Figure 1 — Login screen

Figure 2 — Google OAuth consent

Figure 3 — Home screen, English

Figure 4 — Profile drawer

Figure 5 — Home screen, Telugu

Figure 6 — Voice recording state

Figure 7 — Voice processing state

Figure 8 — Conversation history

Figure 9 — Bible reader, Telugu

Figure 10 — Translation selector

Figure 11 — Book and chapter selector

Figure 12 — Bible reader, English

Figure 13 — Hymn library

Figure 14 — Hymn player

Figure 15 — Subscription plans

Figure 16 — Razorpay checkout

Figure 17 — Payment confirmation

Figure 18 — Home screen with active subscription

Figure 19 — Administrative console, demonstration mode

Figure 20 — Administrative console, users

Figure 21 — Administrative console, webhook audit

Figure 22 — Administrative console, feature flags

Figure 23 — Administrative console, audit trail

Figure 24 — Administrative console, live instance

Figure 25 — Measured pipeline latency, live instance

Figure 26 — Three-tier system architecture

Figure 27 — One voice turn, end to end

Figure 28 — Database schema

Figure 29 — Measured per-stage latency

# LIST OF TABLES

Table 1 — Functional requirements and their implementation status

Table 2 — Non-functional requirements and their verification status

Table 3 — Technology stack and rationale

Table 4 — Database tables

Table 5 — API endpoints

Table 6 — Runtime feature flags

Table 7 — Automated test suite composition

Table 8 — Representative automated test cases

Table 9 — Functional verification on device

Table 10 — Measured pipeline latency

Table 11 — Properties not verified

Table 12 — Defects identified

Table 13 — Corrections to the Phase 3 document

Table 14 — Execution environment

Table 15 — Version control activity

Table 16 — Third-party dependencies and licences

# LIST OF ABBREVIATIONS

| Term | Expansion |
|---|---|
| AAC | Advanced Audio Coding |
| API | Application Programming Interface |
| CD | Continuous Deployment |
| CI | Continuous Integration |
| CVD | Colour Vision Deficiency |
| FR | Functional Requirement |
| HMAC | Hash-based Message Authentication Code |
| JWT | JSON Web Token |
| LLM | Large Language Model |
| MRR | Monthly Recurring Revenue |
| NFR | Non-Functional Requirement |
| OAuth | Open Authorization |
| p50 / p95 | 50th / 95th percentile |
| RLS | Row Level Security |
| REST | Representational State Transfer |
| SDK | Software Development Kit |
| STT | Speech To Text |
| TTS | Text To Speech |
| UVP | Unique Value Proposition |
