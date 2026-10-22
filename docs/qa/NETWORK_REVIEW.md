# Independent Network and API Contract Review

Reviewed: 2026-10-21, Asia/Ho_Chi_Minh  
Files: `lib/core/config/app_config.dart`, `lib/core/network/api_client.dart`, `lib/core/network/api_failure.dart`, `docs/API_CONTRACT.yaml`  
Method: read-only static review. `test/api_client_test.dart` appeared after the initial source review and was inspected, but it was still being authored; no test execution result is claimed here.

## Verification disposition — 2026-10-21

- **PASS:** `flutter test --no-pub test/api_client_test.dart` — exit 0, 17/17 tests passed.
- **PASS:** `flutter analyze --no-pub lib/core/config lib/core/network test/api_client_test.dart` — exit 0, no issues found (4.7 s analyzer time).
- NET-001 resolved: token-reader failures map to redacted `SESSION_UNAVAILABLE`, callback failures cannot replace the safe 401, malformed percent paths become `ArgumentError`, and tests cover each case.
- NET-002 resolved: certificate and unknown transport failures are non-retryable; tests cover both. Transient GET retry remains bounded to one retry.
- NET-003 resolved: concurrent 401 responses await one shared cleanup future and the epoch is checked afterward; the regression test verifies one handler invocation.
- NET-004 resolved in the reviewed constructor: injected Dio interceptors are cleared before bearer use. Production-provider wiring and log inspection remain integration evidence, not established by this unit test.
- NET-005 through NET-008 are addressed at contract level: planned state-changing POSTs now require idempotency; audio documents persisted consent revision, format/magic/size/duration and retention rules; feedback adds source/provenance/completeness plus pronunciation/overall invariants; realtime credentials and audio URLs document scope and bounded lifetime. Implementation, database constraints, provider behavior, private storage, and cloud/device verification remain pending.
- NET-009 remains a contract improvement: explicit `Retry-After` response headers and a stable error-code enumeration were not found in this verification.

The focused network gate is green. This result does not replace full-suite, backend, integration, Supabase, provider, device, or UAT evidence.

## Overall assessment

The new transport is a meaningful security improvement. It confines the base URL to HTTPS or explicitly enabled loopback HTTP, rejects URL credentials/query/fragment, prevents redirects, rejects absolute or traversal request paths, reads the access token immediately before each attempt, never automatically retries mutations, and uses a session epoch plus `CancelToken` to reject responses after account change. `AppConfig.toString` avoids printing the anon key and endpoints. No provider key or service-role key is defined in the mobile configuration.

The OpenAPI document is valid JSON and clearly labels future endpoints as `planned` with permissive schemas explicitly pending. Those placeholders are not counted as implemented. The findings below should be resolved before the affected code or contract is treated as stable.

## Actionable findings

### NET-001 — P1 — Auth callbacks and token readers can escape the typed failure boundary

`ApiClient.request` awaits `_accessToken()` outside the `try` block (`api_client.dart:90`), and awaits `_onUnauthorized` inside the Dio catch without translating callback errors (`:115-121`). A secure-storage/session SDK failure, malformed local auth state, or logout callback failure therefore reaches feature code as an arbitrary exception instead of `ApiFailure`. The same applies to malformed percent escapes because `Uri.decodeComponent` in `_safeRoute` (`:135`) can throw `FormatException`.

Action: translate access-token read and unauthorized-handler failures into stable, non-sensitive `ApiFailure` codes, while preserving `CANCELLED` when the epoch changed. Convert malformed route encoding to `ArgumentError` consistently. Tests should make both callbacks throw and assert that raw exception text and secrets never escape through `toString` or user-facing messages.

### NET-002 — P1 — Retry classification treats certificate and unknown transport failures as retryable

`ApiFailure.fromDio` marks every status-less, non-cancelled exception retryable (`api_failure.dart:70-71`). This includes `DioExceptionType.badCertificate` and may include local TLS/configuration or serialization failures classified as `unknown`. A GET consequently retries a certificate failure once and reports a generic network error. Retrying does not bypass TLS, but it obscures the security/configuration cause and performs unnecessary traffic.

Action: allow automatic retry only for explicit connection/receive/send/connect timeout failures and narrowly classified transient connection errors. Map `badCertificate` to a non-retryable safe code such as `TLS_ERROR`; map unknown local failures conservatively as non-retryable unless proven transient. Add one test each for timeout, connection error, 502/503, bad certificate, cancellation, and unknown exception.

### NET-003 — P2 — Unauthorized coordination is a process-wide boolean, not a shared completion

`_handlingUnauthorized` prevents duplicate logout callbacks, but concurrent 401 requests arriving while the first callback is in progress immediately throw their own 401 failures rather than awaiting the same unauthorized transition. This can let multiple screens render stale auth errors during logout, although `cancelSession` still prevents old successful responses from being returned.

Action: represent unauthorized handling with a shared `Future<void>` and have concurrent 401 paths await it. After it completes, re-check the epoch so requests from the old account resolve as `CANCELLED`, not as UI errors for the new auth state. Test two simultaneous 401 responses and assert one callback plus deterministic cancellation.

### NET-004 — P2 — Injected Dio interceptors remain capable of observing credentials

The constructor overwrites `Dio.options`, which safely fixes base URL and redirect behavior, but an injected `Dio` retains its existing interceptors. A logging interceptor can observe the per-request `Authorization` header. This is useful for tests but means credential-origin confinement depends on composition outside this class.

Action: keep production construction in one audited provider that creates an interceptor-free client or installs only a proven redacting logger. Document that arbitrary injected Dio instances are test-only. Add a regression test for the actual production provider/configuration rather than treating the class alone as proof that tokens cannot be logged.

### NET-005 — P1 contract gap — Several costly or record-creating planned mutations lack idempotency

The contract has strong idempotency language and correctly requires keys for sessions, messages, completion, vocabulary creation, voice bootstrap/completion, and audio turns. It does not require a key for planned `POST /placement/start`, `POST /placement/{id}/submit`, `POST /coach/ask`, or `POST /drills/{id}/attempts`. These operations can create records, invoke providers, update mastery, or consume quota; retries and double taps can duplicate state or cost.

Action: require the same bounded `Idempotency-Key` contract for every non-naturally-idempotent POST before implementation. PATCH and DELETE may rely on HTTP semantics only if their version/concurrency behavior is specified; otherwise add an expected revision/ETag or idempotency key. Define whether keys are scoped by authenticated subject + route + method and whether the canonical request hash includes multipart metadata/content digest.

### NET-006 — P1 contract gap — Audio consent and upload validation are underspecified

`POST /sessions/{id}/audio-turns` contains binary `audio` and a request-level `saveAudio` boolean, but no consent revision/record, maximum bytes, maximum duration, accepted container/codecs, claimed MIME, checksum, sample-rate/channel constraints, or retention result. A client-provided `saveAudio: true` alone is not proof of durable informed consent. The response also does not state whether audio was retained or when deletion occurs.

Action: require a server-side stored consent state/revision and reject retention when it is absent or stale. Specify byte/duration limits and that the server verifies magic bytes/decoded media rather than trusting MIME. Return retention status and expiry when audio is retained. Keep processing ephemeral when consent is false and test that no object path/database retention record is created.

### NET-007 — P1 contract gap — Feedback provenance cannot substantiate all displayed scores

`Feedback.dimensions[].evidence` is an array of free text. It has no source message/turn identifier, audio time range, input-completeness flag, acoustic-evidence flag, assessment/model/prompt version, or ASR/audio confidence. `scorerProvider` and `scorerVersion` are optional. The schema cannot enforce pronunciation N/A without acoustic evidence or absence of overall score when any dimension is invalid.

Action: replace free-text-only provenance with immutable source references (message ID and optional audio offsets), add input/acoustic completeness and scorer lineage, and define an explicit availability/status per dimension. State and test invariants: pronunciation band is null without acoustic evidence; overall is null unless all four dimensions are valid. Keep the planned assessment endpoint pending until it has equivalent detail.

### NET-008 — P2 contract gap — Realtime credential and audio URLs need explicit handling constraints

`VoiceBootstrap.credential` is merely a string, while `Message.audioUrl` is also an unconstrained string. The endpoint summary says the realtime bootstrap is scoped and short-lived, but the schema does not define credential audience/scope, one-time/replay properties, or maximum TTL. Audio URLs do not state that they are private signed URLs with bounded expiry.

Action: document the bootstrap credential's exact scope, audience/session binding, maximum TTL, revocation behavior, and prohibition on logging/persistence. Mark URLs as URI format and document private signed-read TTL; do not serialize long-lived provider credentials or storage paths.

### NET-009 — P2 contract gap — Error responses omit retry timing and standardized concurrency metadata

The error envelope is appropriately bounded, includes `requestId`, and does not expose raw provider errors. However, 429/503 responses have no documented `Retry-After` header, and 409 responses do not distinguish idempotency-key payload mismatch from optimistic-concurrency or session-state conflict in the schema.

Action: document `Retry-After` where applicable and enumerate stable error codes for key reuse, quota, concurrent turn, completed session, provider timeout/invalid response, and assessment processing. This lets the typed client decide whether and when an explicit user retry is safe.

## Required regression evidence

The network test suite should cover:

1. Reject HTTP off loopback, URL user info, query/fragment base URLs, non-`/api/v1` API roots, absolute/scheme-relative/traversal/backslash routes, malformed percent escapes, and invalid idempotency keys.
2. Add `Authorization` only for authenticated calls; never place tokens in URL/query or diagnostics; keep redirects disabled.
3. Cancel requests during token lookup, transport, retry delay, and after response arrival but before return; no old-account payload may complete after `cancelSession`.
4. Two concurrent 401s invoke one unauthorized transition and cannot affect a newly authenticated epoch.
5. GET retries exactly once for approved transient classes; POST/PATCH/PUT/DELETE never auto-retry; the second GET attempt re-reads the token.
6. Map all relevant Dio exception types and 400/401/403/404/409/429/502/503 responses to safe typed failures; reject untrusted server code/request IDs; do not expose server message/body/token.
7. `close` is idempotent and prevents later requests; cancellation is non-retryable.

Until these tests execute, the reviewed behavior is supported by source inspection only and remains unverified at runtime.

## In-progress test review

The newly appearing `test/api_client_test.dart` covers secure base configuration, diagnostic key redaction, route confinement, redirect disabling, missing tokens, one safe GET retry with token refresh, no mutation replay, safe 401 text, no 429 retry, cancellation during token lookup, and stale transport-response rejection. These are useful regression tests.

Coverage still needed for the findings above: throwing token reader; throwing unauthorized callback; malformed percent encoding; concurrent 401 coordination; cancellation during retry delay; `badCertificate`, timeout, connection error, cancel, and unknown Dio types; response status/code mapping beyond 401/429/503; invalid `requestId` and server code rejection; invalid idempotency keys; idempotent `close`; and credential observation through production interceptors. The scripted adapter ignores `cancelFuture`, so the stale-response test proves the epoch backstop but does not prove that the actual adapter aborts network I/O on logout.
