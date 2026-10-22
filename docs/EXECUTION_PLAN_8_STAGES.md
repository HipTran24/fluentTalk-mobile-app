# English Speaking AI four hour execution plan

Execution date: 2026-10-21. Start: 16:13 Asia/Ho_Chi_Minh. Deadline: 20:13 (240 minutes). This is an execution timebox, not evidence that the 28-week baseline can be accepted in four hours.

## Source and precedence

Read PROJECT_MASTER_PLAN.md, mirrored from the supplied Google Doc, revision recorded in its header. Appendices A–E v1.1 supersede original chapter 6 and original post-v1 realtime exclusion. All 20 screens, all three modes, A0–C2, evidence-backed assessment, adaptive coach, privacy and reliability remain requirements. Unfinished requirements must be reported explicitly, never replaced with a simulated success. User amendments: Java 27 backend, eight stages, four-hour implementation, improved professional UI, GPT-6 Sol Antigravity coordinator and GPT-5.6 Sol QA agent.

## Architecture and scope decisions

- Keep Flutter/Dart mobile, Riverpod, GoRouter and five existing tabs. Java 27 applies to the Spring Boot backend, not Android's Java bytecode toolchain or a rewrite of Flutter UI.
- Preserve the existing Flutter project root to avoid breaking active IDE paths during the timebox; add backend/, docs/, infra/ alongside lib/. Record the ADR-006 layout deviation and later migration to mobile/ as a separate mechanical change.
- Supabase Auth/JWKS, PostgreSQL/Flyway, private Storage, Gemini via backend adapters; no privileged provider key in Flutter. Runtime configuration comes from environment, not committed credentials.
- Java 27 is the requested target. Installed JDKs stop at 26. Official Spring Boot stable requirements currently advertise compatibility only through 26. Treat Java 27 compatibility as a measured gate; document actual compiler/runtime/framework results. Do not silently label a Java 21/26 build as Java 27 or upgrade Spring major versions without an ADR.
- Existing local/mock repositories are demo infrastructure. Production mode must use real services or show an explicit unavailable/configuration state. Fake authentication, audio, realtime, scores, analytics and coach evidence must never pass as production behavior.
- Assessments use appendix A5: four axes, estimated 0–9, confidence, lineage, version; pronunciation N/A without acoustic scorer; overall absent unless all four axes are valid. A0 is an internal starter label.

## Responsibilities and safe collaboration

Root agent owns source mirror, execution plan, ADR/changelog, dependency and toolchain setup, integration coordination and final reporting. It may implement explicitly agreed files after notifying the coordinator.

GPT-6 Sol subagent owns directing the Antigravity IDE AI, phase-by-phase task prompts, implementation scopes and acceptance evidence. It alone operates Antigravity to avoid UI races. First inspect actual available UI; never claim that a prompt was delivered if it was not. If the IDE is unavailable or needs login/approval, save exact prompt to docs/antigravity/ and ask root to notify the human. If external IDE work is blocked, root may allocate code implementation directly; label who wrote it accurately.

GPT-5.6 Sol subagent owns independent QA, baseline analyze/tests, traceability, security/contract/performance review and regression verification. Initial role read-only except docs/qa/ and test evidence. Additional test code must use isolated agreed files; do not edit implementation while the IDE edits it. It reports P0/P1 with exact reproduction and does not mark tests passed unless executed. No extra subagents unless root authorizes them.

Agents share files. Never revert the user's pre-existing pubspec.lock diff. Never reset/clean working tree. Do not push, merge, deploy or publish during implementation. User handles external account/hosting/device steps when needed. No credentials in chat, repository, prompts or logs.

## Stage 1 Foundation and reproducible baseline

Time: 16:13–16:33, 20 minutes. Task IDs ESP-S1-01 through ESP-S1-05. Baseline D v0.1 plus technical amendment.

1. Mirror the supplied plan, log amendments and record environment, Git status and installed Flutter/Java/Maven/Android tooling.
2. Run Flutter analyze and current nine test files once; retain actual failures as baseline defects.
3. Add Java 27 backend skeleton, environment validation, public sanitized /api/v1/health, request IDs and standard error schema. Verify framework compatibility before choosing dependency versions.
4. Add reproducible build/test commands and CI skeleton, .env.example with empty variables, local infrastructure and gitignore for secrets/toolchains.
5. Specify OpenAPI and migration contracts before client implementation. Keep source readback and requirement matrix.

Gate: source mirrored, commands reproduce baseline, health endpoint and backend compile/test attempted with explicit JDK version, external prerequisites listed. Java 27 unsupported/missing is a release blocker, not permission to claim success.

## Stage 2 Persistent identity and professional design system

Time: 16:33–17:08, 35 minutes. ESP-S2-01..06. AUTH-01..05, PROFILE-01..02, screens 01–05 and 20, D v0.2.

1. Configure Supabase initialization before routing; secure session persistence and refresh events; await restore; handle offline/revoked/deleted/error states; guard all authenticated deep links including admin with explicit role policy.
2. Replace fake login/register/reset with Supabase, preserve form validation, disable duplicate submits; logout stops media and clears account-scoped providers/cache.
3. Backend JWT verification checks signature/JWKS, issuer, audience, expiry; derive subject server-side. /me ownership and profile/settings migration with RLS, including two-user denial tests.
4. Refine common theme: indigo #4F46E5, teal #0D9488, calm background #F8FAFC, restrained gradients, consistent 8pt spacing, 16–20dp cards, readable 14–16sp body, 48dp touch targets, semantic labels and reduced motion.
5. Make auth/onboarding keyboard-safe and support 320dp/200% text. Preserve 5 tabs. Apply common components so the improvement reaches all 20 screens, then inspect representative screenshots.

Gate: real sign in/reopen/sign out verified when configured; otherwise mark external UAT pending. No token/password logging, no fake production auth. Golden/screenshot and narrow-width UI evidence required.

## Stage 3 Curriculum and real catalog

Time: 17:08–17:33, 25 minutes. ESP-S3-01..05. TOPIC-01, SCENARIO-01, placement, screens 05–09, D v0.3.

1. Define A0–C2 goals and placement tasks, manual/skip choice, confidence and limitations. Never infer official CEFR or IELTS certification.
2. Flyway seeds at least 12 scenarios across introduction, daily life, travel and work; UUID identifiers, active state, roles, level, objectives and duration.
3. Implement paginated topic/scenario/detail APIs with indexes and validated filters; Flutter reads metadata via configured API client rather than a hardcoded production catalog.
4. Home, practice hub, catalog and setup gain clear hierarchy, primary CTA, honest first-use/empty states and loading/error/retry.
5. Keep original recognized transcript separate from later user annotations.

Gate: database/API seed counts and filter tests; learner reaches setup from home with clear actions; all levels represented in curriculum metadata; placement acoustic confidence remains pending without real audio tests.

## Stage 4 Durable AI text to speech conversation

Time: 17:33–18:13, 40 minutes. ESP-S4-01..07. MODE-01, CHAT-01..05, OPS-01..03, screen 10, D v0.4.

1. OpenAPI/DTO and Flyway sessions/messages/usage contracts first. Ownership queries use authenticated subject, unique sequence and idempotency constraints.
2. Implement create/list/read/send/complete APIs. Bound page size, input length, history context and upstream timeout; serialize concurrent session turns safely.
3. Gemini provider adapter with model from environment; strict ai_turn_v1 validation, bounded invalid-JSON retry, clear upstream errors and request IDs. No fabricated fallback that claims a successful provider response.
4. Per-user quota and concurrency protection; retries cannot double-charge or duplicate user/AI messages. Do not retry unsafe mutations without persisted idempotency.
5. Wire Flutter network client, typed errors, expired-token handling, thinking state, recoverable retry; durable history.
6. Real TTS/audio playback with replay and 0.75/1/1.25x; expose unsupported audio clearly. Never return mock audio paths as success.
7. Tests: duplicate key, wrong owner, invalid JSON, provider timeout, empty output, completed session write, double tap and redacted logs.

Gate: typed question yields matching audible response when provider/OS configured, persisted once and readable after restart. Mock provider tests verify resilience but do not establish real-provider success.

## Stage 5 Guided speaking and audio privacy

Time: 18:13–18:43, 30 minutes. ESP-S5-01..06. MODE-02, VOICE-01..04, UAT-08, screen 11, D v0.5.

1. Real recording permissions and lifecycle; no recording before consent, handle mic denied/revoked/background interruption, stop/dispose resources on navigation/logout.
2. Guided state machine idle → aiSpeaking → waitingForUser → recording → transcribing → generating → aiSpeaking/recoverableError → ended.
3. STT → transcript/timing → Gemini → TTS orchestration via configured providers. Preserve raw ASR text and confidence.
4. Validate audio MIME/magic, size and duration; reject malformed payloads. Storage private, short-lived signed reads, no retained audio by default; consent version and deletion policy if retention enabled.
5. Text fallback, repeat/translate/hint, playback speed, retry without duplicate turn.
6. Tests for mic denied, empty audio, malicious content type, oversize input, provider failure, consent false and cleanup.

Gate: real Android speak → transcript → audible AI response, with consent false proving no retained audio. Device-dependent checks remain unverified until exercised on a device.

## Stage 6 Realtime voice and recovery

Time: 18:43–19:08, 25 minutes. ESP-S6-01..05. MODE-03, appendix C1/C3, screen 12, D v0.6.

1. Run minimal transport spike before committing design: current Gemini Live protocol, token TTL, audio formats/rates, quota enforcement and server usage reconciliation.
2. Record ADR with measured transport and provider limitations. Authorized bootstrap returns only scoped short-lived credentials, never the Gemini long-lived key.
3. Implement call states, actual input/output streams, captions, VAD/interruption if supported, mute/end, reconnect and fallback to guided.
4. Persist meaningful events/checkpoints; hangup does not wait for full scoring. Dispose media on logout/background/permission loss.
5. Measure first audible latency, dropped connections, resume behavior and costs; prepare the baseline 30-call matrix for Wi-Fi/mobile and audio focus.

Gate: real two-way call with graceful end and recovery; 30-call results are required for beta acceptance. If transport/credentials/device are unavailable, keep realtime explicitly unavailable or beta and log the blocker. Never animate a fake call as a real implementation.

## Stage 7 Evidence backed feedback coach and progress

Time: 19:08–19:43, 35 minutes. ESP-S7-01..07. FEEDBACK-01..04, SCORE-01..04, COACH-01..06, PROGRESS-01..02, NOTIFY-01, screens 13–20, D v0.7–0.8.

1. Idempotent session completion schedules assessment; immutable rubric revisions, transcript evidence, confidence/model/input completeness. Pronunciation N/A without acoustic engine, overall absent unless all four dimensions valid.
2. Assessments, dimensions, weaknesses, memory lineage, plans, drills, attempts, privacy preferences through Flyway, ownership and versioned APIs.
3. Deterministic coach prioritizes recurrence × impact × recency × confidence; recommendations trace to real source sessions. Do not invent progress from insufficient samples or update historical scores.
4. Weekly plan and drills, user-controlled memory/personalization, save/master/delete vocabulary. Deleting a source hides/removes derived memory according to policy.
5. Progress computed from completed sessions, UTC persistence and Asia/Ho_Chi_Minh day boundaries, missing dimensions are gaps rather than zero.
6. Improve summary/history/coach/profile screen composition and empty states; chart accessible text summaries, opt-in reminders and consent settings.
7. Validate structured outputs on 100 fixtures and report validity; human calibration remains a separate explicit acceptance dependency.

Gate: an actual session yields evidence-linked feedback and progress; repeated errors across three sessions yield a matching drill; privacy and cross-user tests pass. Unimplemented acoustic scoring remains N/A.

## Stage 8 Hardening performance and delivery

Time: 19:43–20:13, 30 minutes. ESP-S8-01..07. D v0.9–1.0, UAT-01..09.

1. Freeze features; independent QA reviews changed contracts, migrations, ownership, secrets, retries, quota, duplicate submits and disposal. Fix P0/P1 before cosmetic changes.
2. Run analyze/test/backend verify, PostgreSQL migrations from clean database, production config checks, Android debug/release build as signing permits, representative UI screenshots at 320dp/200% scale.
3. Exercise UAT-01..09, network timeout/loss, token expiry, AI invalid JSON, quota limit, concurrent idempotency, consent denied, memory deletion and crash recovery.
4. Benchmark ordinary API p50/p95 excluding provider latency; target p95 <800ms. Measure AI latency/cost separately. Profile Flutter release/profile build for jank; do not claim smoothness from debug tests alone.
5. Record each command, environment, elapsed time, result and unresolved defects; do not reinterpret unit mocks as real device/provider tests.
6. Produce install/run guide, .env.example, API/schema, acceptance report, known issues, deployment steps and rollback/backup checklist.
7. Only label release candidate if zero known P0/P1 and critical gates pass. v1.0 tag and production deployment require actual acceptance and user action, per baseline.

Gate: reviewable code and reproducible evidence. Any missing external service, unsupported Java 27, device test, human calibration, 30-call test or unmet UAT remains in release blockers. Completing the timebox is distinct from completing the product.

## External prerequisites for the human

1. Open this repository in Antigravity and sign in/enable its AI if requested by UI; approve IDE execution only after reading its requested action.
2. Create a development Supabase project, configure email/password Auth, redirect URLs, database connection and private audio bucket. Set local environment values; do not paste service_role/database passwords into chat.
3. Enable Gemini billing/API with project budget alerts; set GEMINI_API_KEY and model IDs locally. Choose speech/live providers only after their capabilities are verified. No paid provisioning without human action.
4. Provide Android device/emulator and microphone permission for audio tests; iOS signing and store publication are separate manual steps.
5. Configure hosting/TLS and staging secrets when deployment is ready. Development must fail clearly when required config is absent.

## Quota and checkpoints

Initial Codex usage read: 2% used of the shared 300-minute window, 0% of weekly window, no extra credits. This is not a guarantee that four hours of multi-agent work fit. Root checks meter at stage boundaries or meaningful usage changes, batches reads/tests, uses only the two requested agents and avoids idle polling. Above 70% used, prioritize core flow and evidence; above 85%, stop optional polish and reserve capacity for fixes/reporting; actual account limits take precedence. Agents report concise changed paths and test evidence rather than repeating full files. Antigravity quota is a separate system and must be observed from its real UI.

At each stage update docs/SPRINT_LOG.md: done with evidence, in progress, blocked and remaining. If a stage overruns, preserve all unmet requirements in the backlog and continue the dependency critical path; never silently drop scope or report eight accepted stages merely because 240 minutes elapsed.

## Requirement traceability

| Baseline | Stage | Required evidence |
|---|---|---|
| D v0.1; ADR-001..007 | 1 | toolchain/build/migrations/contracts |
| AUTH-01..05; PROFILE-01..02; UAT-01/07 | 2 | real persisted auth, JWT/IDOR tests |
| placement A0–C2; TOPIC-01; SCENARIO-01; G2 | 3 | curriculum, 12 seeds/4 topics, filter tests |
| MODE-01; CHAT-01..05; UAT-02 | 4 | real AI/audio, persistence/idempotency |
| MODE-02; VOICE-01..04; UAT-03/08 | 5 | device mic/STT/TTS, consent tests |
| MODE-03; UAT-04; appendix C | 6 | transport ADR, scoped token, 30-call report |
| SCORE/FEEDBACK/COACH/PROGRESS; UAT-05/06 | 7 | provenance, N/A, deterministic drills, real aggregates |
| UAT-01..09; G3..G6; D v0.9/v1.0 | 8 | measured security/performance/device/UI acceptance |
