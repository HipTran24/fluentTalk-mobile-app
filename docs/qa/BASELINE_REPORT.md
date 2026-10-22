# Independent QA Baseline Report

Date/time: 2026-10-21 16:14–16:18 Asia/Ho_Chi_Minh  
Repository revision at capture: `e534949`  
Execution window: 2026-10-21 16:13–20:13 Asia/Ho_Chi_Minh  
Scope: pre-implementation Flutter baseline and static architecture review. This report does not claim production readiness.

## Environment and preservation

- Flutter 3.47.5 stable, framework revision `6a19cca564`; Dart 3.13.4; DevTools 2.60.0.
- The repository contained a pre-existing modified `pubspec.lock`. QA did not edit or regenerate it.
- At command start the repository had no `backend/` or `integration_test/` tree. Nine Dart files existed under `test/`.
- QA initially owns only `docs/qa/`; no implementation, dependency, or existing test file was edited.

## Executed baseline commands

### `flutter analyze --no-pub`

- Result: **FAIL**, exit code 1.
- Tool-reported duration: 1.7 s; wall time: 3.35 s.
- Diagnostics: 158 total. Three are compile-blocking errors:
  - `lib/core/theme/app_theme.dart:52`: `CardTheme` is not assignable to `CardThemeData?`.
  - `lib/core/theme/app_theme.dart:171`: `DialogTheme` is not assignable to `DialogThemeData?`.
  - `lib/core/theme/app_theme.dart:244`: `CardTheme` is not assignable to `CardThemeData?`.
- The remaining diagnostics are analyzer information findings, predominantly deprecated Flutter APIs such as `withOpacity`, old radio/dropdown properties, and `activeColor`.

Reproduction:

```sh
cd /Users/ProM2/Documents/engish-app/english_mobile_app
flutter analyze --no-pub
```

### `flutter test --no-pub`

- Result: **FAIL**, exit code 1.
- Wall time: 19.82 s.
- Final runner count: **44 passed, 6 failed/error** (`+44 -6`). This is not a passing test suite.
- `test/widget_test.dart` failed to compile because of the three theme errors above and a `google_fonts 6.3.0` constant-evaluation incompatibility involving `FontWeight` under the installed Flutter/Dart SDK.
- Reported widget failures include:
  - `SessionSummaryScreen (Screen 13) renders rubric report and disclaimer`
  - `ProgressScreen (Screen 14) renders period toggle, stat cards, and chart`
  - `HistoryScreen (Screen 15) renders search bar, filters, and session list`
  - `WeeklyPlanScreen (Screen 18) renders 7-day plan with today badge`
  - `ProfileScreen (Screen 20) renders identity card and privacy settings`
- The common runtime assertion is: a `ListTile` is wrapped by a colored `DecoratedBox`, which can hide its Material background and ink effects. The runner summarized two additional failing entries beyond the four printed in its truncated final list; the complete command result is therefore represented by the authoritative `+44 -6` count, without guessing the omitted name.

Reproduction:

```sh
cd /Users/ProM2/Documents/engish-app/english_mobile_app
flutter test --no-pub
```

## Baseline defects and release blockers

### QA-BL-001 — P0 — Local fake authentication grants access to arbitrary credentials

`LocalAuthRepository.signIn` accepts any syntactically valid email and any password of six or more characters, creates a user when one does not exist, writes a fabricated `mock_jwt_token_*` value to `SharedPreferences`, and marks the account onboarded (`lib/features/auth/data/auth_repository.dart:88-119`). The active provider selects this repository unconditionally (`lib/features/auth/presentation/controllers/auth_controller.dart:5-7`). This is not authentication and must never be reachable as production behavior.

Related gaps: there is no Supabase session/JWKS validation, expiry/revocation handling, secure token storage, auth stream, or two-user authorization boundary. Errors during onboarding explicitly transition to authenticated state (`auth_controller.dart:119-123`). UAT-01 and UAT-07 are **pending**, not passed.

### QA-BL-002 — P0 — Authenticated and admin routes have no guard or role enforcement

`app_router.dart` exposes `/admin`, practice, feedback, history, coach, profile, and the five authenticated tabs without a router redirect or authorization check. Navigating directly to `/admin` has no demonstrated role policy. Combined with QA-BL-001, this blocks any security acceptance or release claim.

### QA-BL-003 — P0 — Mock/simulated product functions are wired as live providers

Production-facing Riverpod providers directly instantiate mock repositories for chat, guided speaking, realtime, feedback/progress, profile/vocabulary, coach, and other flows. Concrete examples:

- `chat_controller.dart:5-7` selects `MockChatRepository`; playback state is toggled without an audio engine (`:119-126`).
- `guided_controller.dart` selects `MockGuidedSpeakingRepository`; the UI timer represents recording, while repository methods return fabricated transcripts and `mock_audio_*.mp3` paths.
- `realtime_controller.dart` selects `MockRealtimeCallRepository` and drives simulated speech, captions, replies, and a hard-coded latency using timers.
- `feedback_repository.dart:12-71` returns fabricated transcript evidence, score 6.0 overall, and pronunciation 6.0 with claimed acoustic evidence.
- `profile_repository.dart:15-108` returns fabricated vocabulary and treats settings/audio deletion as delays with no persistence or deletion.

There is no environment boundary that makes these screens explicitly demo-only or unavailable. This violates the execution plan rule against misleading fake production functions. UAT-02 through UAT-08 cannot be inferred from mock unit tests.

### QA-BL-004 — P1 — Current Flutter application/test target does not compile cleanly

The three theme API errors make analysis fail and prevent at least the root widget test from loading. The dependency/SDK incompatibility in `google_fonts` is a second compile blocker in the test run. Exact reproduction is the two commands above.

### QA-BL-005 — P1 — Existing widget tests detect invalid Material composition

Multiple screens trigger Flutter's `ListTile` under colored `DecoratedBox` assertion. This affects current feedback, progress, history, plan, and profile UI tests. These failures must be fixed and the full suite re-executed; passing repository tests do not offset failed widget/runtime assertions.

### QA-BL-006 — P1 — No durable security, idempotency, concurrency, quota, or provider-failure boundary exists at baseline

There was no backend at baseline. A timestamp/hash string named `idempotencyKey` is generated in the chat controller, but the selected in-memory mock cannot establish persistent deduplication, atomic charging, ordered concurrent turns, ownership, or replay behavior. No executed baseline evidence covers JWT signature/issuer/audience/expiry, IDOR, 409/429 handling, upstream invalid JSON, bounded retry, timeout/circuit behavior, or log redaction.

### QA-BL-007 — P1 — Consent and media lifecycle are UI state, not enforced controls

The profile's audio-consent setting and delete-audio operation target a mock repository and have no storage effect. Guided speaking changes state to `recording` and fabricates STT without obtaining a real audio stream. Realtime is timer simulation. Therefore no evidence shows that consent denial prevents capture/retention, private storage and TTL work, permission revocation is handled, or audio resources are stopped on navigation/background/logout. UAT-08 is **pending**.

### QA-BL-008 — P1 — Score provenance contract is incomplete and fabricated data can look authoritative

The model supports nullable bands and a pronunciation acoustic-evidence flag, but the active feedback mock supplies four numeric bands, overall 6.0, pronunciation 6.0, and `hasAcousticEvidence: true` without an acoustic scorer. `AssessmentReport` has rubric version but lacks the complete source/model/input lineage required by Appendix A5. There is no demonstrated invariant that overall is absent unless all four axes are valid. UAT-05 is **pending**.

### QA-BL-009 — P1 — Accessibility acceptance has no baseline evidence

No test or captured device run exercises a 320 dp viewport with 200% text scale. The existing widget suite is red. Critical-action reachability, overflow, semantic labels/focus order, reduced motion, contrast, and keyboard-safe layouts remain **pending**. UAT-09 is **pending**.

## Independent quality gates for subsequent verification

The following gates must be evaluated against changed code. A gate remains pending until its command or manual procedure is actually executed.

1. **Build/static gate:** `flutter analyze --no-pub` exits 0; full `flutter test --no-pub` exits 0. Backend compilation/tests must report the exact Java runtime, with Java 27 evidence distinct from Java 26 or earlier.
2. **Production-boundary gate:** startup selects real configured adapters, while missing configuration produces a clear unavailable state. No mock auth, audio, realtime, scoring, progress, coach, deletion, or analytics is presented as successful production behavior.
3. **Auth/IDOR gate:** two real test identities; valid/expired/revoked/wrong issuer/wrong audience JWT cases; all owner-scoped session, history, memory, vocabulary, feedback, and audio endpoints deny cross-account access; admin route and API require a verified role.
4. **Mutation-integrity gate:** persisted idempotency keys, duplicate-submit tests, concurrent same-session turns, ordered sequence constraints, quota atomicity, completed-session write denial, and retries that neither duplicate messages nor double-charge.
5. **Provider-resilience gate:** invalid JSON, empty output, timeout, 429, 5xx, disconnect, bounded retry, circuit/open state, request ID, and redacted logs. Mock-provider tests establish logic only; real-provider UAT remains separate.
6. **Consent/media gate:** consent false causes no retained audio; MIME/magic/size/duration rejection; private storage and signed-read TTL; explicit deletion; mic denied/revoked/background/logout/navigation cleanup; controllers/streams/timers disposed.
7. **Assessment gate:** evidence snippets trace to immutable transcript turns; rubric/model/prompt/input-completeness lineage and confidence persist; pronunciation is N/A without acoustic evidence; overall is absent when any axis is invalid; 100-fixture structured-output result is measured, with human calibration separately pending.
8. **UX/accessibility gate:** representative screens at 320 dp and 200% text, keyboard and safe-area checks, critical actions reachable, meaningful semantics/focus order, loading/empty/offline/unauthorized/error states, and no test-framework assertions.
9. **Performance gate:** ordinary backend API p50/p95 measured separately from AI/provider latency, with data set, hardware, concurrency, warmup, and timestamps recorded; Flutter profile/release jank and real voice latency measured. No performance claim from mocks or debug tests.
10. **Acceptance gate:** execute and record UAT-01 through UAT-09 individually. At baseline all nine are pending. External device, Supabase, Gemini/speech/live provider, 30-call reliability matrix, and human score calibration remain release dependencies until exercised.

## Baseline conclusion

The baseline is a substantial UI/demo scaffold with some unit coverage, but it is not build-clean and its core product paths are simulations. The existing tests do not establish real authentication, authorization, persistence, audio, AI, scoring, privacy, reliability, accessibility, or performance. The four-hour timebox cannot establish completion of the 28-week scope; any unexecuted gate above remains a documented release blocker or pending dependency.
