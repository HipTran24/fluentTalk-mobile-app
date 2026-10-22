# Final Independent QA Handoff

Snapshot reviewed: 2026-10-21 21:00–final frozen auth handoff, Asia/Ho_Chi_Minh. The requested 16:13–20:13 four-hour timebox had expired before this audit. This report describes only executed evidence and inspected source; it does not certify the 28-week plan or all eight stages.

## Independently executed evidence

### Backend Java 27 gate

Command:

```sh
cd backend
JAVA_HOME=/Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home \
PATH=/Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home/bin:$PATH \
./mvnw verify -B
```

Result: completed successfully under **OpenJDK 27.0.1**. Spring test startup logged Java 27.0.1. Surefire reports contain **25 tests, 0 failures, 0 errors, 0 skipped**:

- application context 1
- production environment validation 5
- curriculum integration 7
- auth/profile integration 6
- health endpoint 2
- error handling 4

Artifact: `backend/target/backend-0.1.0-SNAPSHOT.jar`. `javap -verbose` on `EnglishSpeakingAiApplication.class` reports **major version 71**, confirming Java 27 bytecode.

Limit: the build uses Spring Boot **4.2.0-M2** / Spring Framework milestone components. Successful compilation/tests prove this repository snapshot runs on this JDK; they do not establish stable-framework vendor support or production suitability. Maven also emitted reflective/final-field compatibility warnings. Java 27 production compatibility remains a release decision requiring a stable supported framework or explicit accepted risk.

### Clean PostgreSQL and packaged API smoke

Root subsequently executed, without rerunning the unchanged Maven suite:

- Fresh PostgreSQL 17 database `esp_final`: Flyway 11.2 migrated and validated V1–V3, exit 0. SQL readback confirmed **4 topics and 12 scenarios**.
- Packaged Java 27 JAR against that fresh database with local RSA/JWKS fixtures: **14/14 checks passed**. Machine-readable evidence is `docs/qa/local-api-smoke.json`.
- Checks include sanitized health, anonymous denial, expired/wrong-issuer/wrong-audience/tampered JWT denial, two profile owners saving and reading isolated records, user-controlled admin metadata denied, verified `app_metadata` admin allowed, four topics, and exact catalog pagination.

This is meaningful local runtime evidence. Identity was locally signed RSA/JWKS, not Supabase cloud; it does not prove cloud auth, RLS, every owner-scoped endpoint, or full IDOR coverage.

## Scope actually present and verified

- Stage 1 foundation is partial: Java backend bootstrap, sanitized health/error/request IDs, production configuration checks, Java 27 build, OpenAPI baseline, mobile configuration/network layer, and local automated tests exist.
- Stage 2 identity is partial: Supabase mobile repository, backend JWT/JWKS verification and `/me` profile/settings code exist; six backend integration tests and the focused mobile lifecycle/guard/DTO suites pass locally. The packaged API smoke establishes two-owner profile isolation with local JWT fixtures. Real Supabase session persistence, revocation, cloud JWKS, RLS behavior under Supabase roles, and full two-user cloud IDOR remain untested.
- Stage 3 catalog is partial: topics/scenarios schema, service/controller/DTOs, filtering/pagination, clean PostgreSQL migration, 4/12 seed readback, and packaged runtime pagination checks exist.
- Stages 4–8 are not implemented end to end. Existing Flutter chat, voice, realtime, feedback, progress, coach, privacy deletion, and related screens continue to rely substantially on mock/simulated repositories. They must not be presented as production-complete behavior.

## Stage 3 catalog audit

What matches the contract:

- DTO property names and shapes for Topic, Scenario, and paginated scenarios match `docs/API_CONTRACT.yaml`.
- Controller routes match `/api/v1/topics`, `/api/v1/scenarios`, and `/api/v1/scenarios/{id}`.
- Migration V3 contains exactly **4 topic rows** and **12 scenario rows**, distributed three per required topic.
- Level CHECK allows A0–C2; active-only detail lookup, keyword/topic/level filters, bounded page and size, and unknown-detail 404 have local tests.

Significant residuals:

1. **P1 curriculum coverage:** the 12 seeds contain only A1, A2, B1, and B2. There are no A0, C1, or C2 scenarios, so the Stage 3 gate “all levels represented” is not met even though the contract accepts A0–C2.
2. **Resolved:** ADR-010 explicitly selects public read-only active catalog content, and OpenAPI now overrides catalog operations with `security: []`, aligned with `SecurityConfig`. DTOs exclude system prompts and user data.
3. **P2 validation mismatch:** OpenAPI bounds `q` to 100 and page/size ranges; the service silently clamps page/size and does not bound `q`. Invalid levels normalize to a database filter rather than being rejected against the contract enum. Add controller validation or document the actual normalization semantics.
4. **Resolved locally:** the earlier migration evidence gap is closed by the fresh PostgreSQL 17 V1–V3 migration/validation and SQL 4/12 readback. Cloud PostgreSQL remains untested.

## AUTH_REVIEW disposition at final frozen snapshot

- **Resolved and locally tested:** one stable/disposed router; loading fails closed; user metadata cannot grant admin; sanitized Supabase initialization failure becomes unconfigured; auth stream handles refresh/sign-out/deletion; operation epochs reject stale completions; logout is immediate, single-flight, cancels `ApiClient`, and invalidates the listed core account caches. Backend independently requires `ROLE_ADMIN`.
- **Production mock boundary added:** non-demo authenticated/onboarding identities are redirected to `/unavailable`, so unfinished learning/privacy/admin screens cannot silently show simulated success. Explicit demo mode has a global visible `DEMO` banner and semantic label.
- Focused results reported from frozen source: auth lifecycle **4/4**, router guards **3/3** after the unavailable-route case, network **17/17**, assessment integrity **5/5**, Stage 2 auth security **6/6**, and `/me` DTO **1/1** — **36 focused tests passed**. The network 17/17 subset was also independently rerun by QA earlier.
- **Residual cleanup gate:** account cleanup invalidates home/chat/progress/history/profile/vocabulary/coach/plan/catalog state, but guided-speaking, realtime-call, drill-player, feedback/session-summary families and real media resources are not covered. Those production functions remain unavailable; implement and test disposal before enabling them.

## Release and acceptance status

This snapshot is **not a release candidate**. Known critical/major gaps and all external acceptance dependencies remain.

- UAT-01 through UAT-09: **pending**. None was executed end to end against configured cloud services and a device.
- Android device list was empty; 320 dp/200% device UX, microphone lifecycle, real recording/STT/TTS, audio focus, background/revocation cleanup, and release/profile jank remain pending.
- Supabase/cloud PostgreSQL/RLS/private Storage and real two-account IDOR remain pending.
- Gemini, speech, TTS, and realtime providers were unavailable; no live AI/audio/realtime success, invalid-output recovery, quota/cost, latency, or 30-call matrix was measured.
- Feedback fixture validity, human calibration, acoustic pronunciation scoring, provenance against real transcripts, and pronunciation N/A behavior in a real flow remain pending.
- Idempotency/concurrency/double-charge behavior for durable session/message/audio mutations is contract-level only because Stage 4–6 backend implementations are absent.
- Full Flutter status is not final: the prior complete run was **84/84 passed** before the last guard test; the expected 85-test rerun was pending at this snapshot. Do not infer 85/85.
- Full `flutter analyze --no-pub` previously exited 1 with **155 information/deprecation diagnostics**; a final clean analyzer result was pending.
- Android APK first attempt failed because Flutter used Java 25 with Gradle 8.5. Root's isolated Flutter/XDG Java 21 retry was still in progress; no APK success is claimed.
- Ordinary API p50/p95, Android device/profile performance, signing, deployment, rollback/backup, and production database operations remain pending unless separately recorded after this snapshot.

The defensible handoff is: Java 27 foundation, clean local PostgreSQL migration, packaged local JWT/profile/catalog smoke, and focused mobile auth/network integrity are green. Production identities are fail-closed from unfinished learning screens. The professional Flutter UI remains a visibly labelled demo when explicitly enabled; production AI speaking, audio, realtime, assessment, adaptive coaching, privacy lifecycle, hardening, Android build acceptance, and UAT are unfinished.

## Root final verification addendum — 2026-10-21 21:28 local

The preceding QA snapshot is retained as the independent review record. Root subsequently completed the frozen-source full Flutter run: **85/85 passed**, exit 0 (`final-flutter-tests.log` in the local task cache). Root also removed the unused Stage 2 test import and ran `flutter analyze --no-pub --no-fatal-infos`: **0 errors, 0 warnings, 158 infos**, exit 0. This does not mean strict analysis is clean; informational/deprecation debt remains.

Android build exposed old project toolchain constraints: the Windows-specific `org.gradle.java.home` was removed, and the isolated JDK 21 retry identified Flutter's minimum Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 requirements. Root updated the wrapper to 8.14.3, AGP to 8.11.1, Kotlin to 2.2.20 and NDK selection to `flutter.ndkVersion`. The rebuild result is recorded in FINAL_STATUS.md when complete. No device, real audio, cloud UAT or performance gate is implied by this toolchain change.

The current versions satisfy Flutter's hard minimum but still emit future-support warnings recommending newer Gradle/AGP/Kotlin. Build resources were bounded to a 2 GB Gradle heap, 768 MB Kotlin daemon and 2 workers on this 8 GB machine. A release-specific residual remains: the main Android manifest does not explicitly declare INTERNET (debug overlays do), so network permission and release signing/configuration must be verified before any release build. This snapshot's Android target is a demo debug preview only.

**Final Android result:** root's bounded-memory retry exited **1** after **778.2 seconds**, reporting `java.io.IOException: No space left on device` during Gradle transforms. **No APK exists.** SDK installation/version validation progress is not a successful build. See `android-build-result.json`. Root stopped its Gradle/Kotlin daemons and deleted its downloaded JDK/Gradle archives, retaining extracted toolchains and source; disk readback recovered to approximately 2.7 GiB available. More free disk and a successful repeat build are required before Android packaging acceptance. No production/release acceptance is granted.
