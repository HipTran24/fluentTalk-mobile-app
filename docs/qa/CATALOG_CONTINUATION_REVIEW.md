# Catalog continuation static review

Snapshot: 2026-10-21, after the original four-hour timebox. This was a source-only review; no test, analyze, build, backend, database, or device command was run. Root's in-progress fixes for the four 320dp/200% detail overflows, refresh error propagation, and exact public-detail route matching are intentionally omitted here.

## Actionable findings

1. **P1 — Production welcome still advertises unavailable AI results and an absolute privacy guarantee.** `lib/features/auth/presentation/welcome_screen.dart:31`, `:42`, `:53`, and `:215` promise an intelligent 1:1 tutor, immediate AI correction, per-session scores, and that audio is “bảo mật tuyệt đối.” The production router blocks these learning functions, and no live AI/audio/cloud/privacy UAT exists. A production, unauthenticated user sees these claims before choosing the real public catalog at `:198-202`. Gate this copy by explicit demo mode or rewrite it as future capability; link the privacy text to the actual policy and avoid an absolute guarantee.

2. **P2 — The client does not enforce the contract's closed camelCase DTOs.** `docs/API_CONTRACT.yaml:5187` and `:5268` set `additionalProperties: false`, but `lib/features/scenarios/data/remote_scenario_repository.dart:29-43`, `:144-168`, and `:171-206` accept unknown keys at the topic, scenario, vocabulary, and page-object levels. Thus a mixed/incorrect payload can pass as long as the expected camelCase fields are also present, weakening the requested strict contract boundary. Validate allowed key sets (including the optional documented fields), and add rejection cases for snake_case/mixed-case and unknown provenance/provider fields.

3. **P2 — The catalog regression suite does not exercise last-write-wins or catalog accessibility.** `test/catalog_api_test.dart:153-168` performs page/filter requests sequentially, so it cannot detect an older delayed response replacing a newer query. `:211-236` checks only the detail screen at 320dp/200%; the catalog itself, welcome entry, unavailable entry, and public-route boundary have no equivalent coverage here. Add a controlled out-of-order two-query test and widget/router cases at 320dp/200% (including long server strings) that assert no overflow and that only `/practice/scenarios` plus one valid detail segment bypass auth.

## Confirmed from source

Production chooses `RemoteScenarioRepository` and never falls back to local data (`scenario_controller.dart:8-11`). Public catalog requests use `authenticated: false` (`remote_scenario_repository.dart:27`, `:89`, `:119`), production bookmarks/curated tabs are disabled, and the production detail start action is disabled rather than reporting fake conversation success (`scenario_detail_screen.dart:189-220`). These are static observations, not newly executed evidence.

## Follow-up disposition (source snapshot after root fixes)

- **P1 welcome copy: resolved by static inspection.** `welcome_screen.dart:44-104` now describes the implemented catalog, offers catalog/auth entry points, and explicitly says online conversation is still being integrated. The unsupported AI-result and absolute-privacy claims are gone.
- **P2 closed DTO parsing: resolved by static inspection.** `remote_scenario_repository.dart:30`, `:88-106`, `:147-152`, `:178-225` now enforce allowed keys, exact integer pagination fields, documented optional-field semantics, vocabulary keys, and active-only scenarios. Executed Flutter evidence remains with root.
- **P2 regression coverage: pending execution.** QA strengthened `CurriculumIntegrationTest.getScenarios_deterministicPaginationOrder` to traverse three pages of five active rows sharing one `createdAt`, assert the UUID tie-break order, and exclude a sixth inactive row. Maven execution awaits the allocated resource slot. Root is separately adding Flutter last-write/accessibility/route coverage.
- **Unicode/V4 static check: no new blocker found.** Backend query validation counts Unicode code points (`CurriculumService.java:70-76`), and the integration test covers 100/101 supplementary-code-point boundaries. V4 is additive/idempotent by fixed UUID and `ON CONFLICT (id) DO NOTHING`, contains five active A0/C1/C2 scenarios, and uses JSON keys matching the public DTO vocabulary shape. Database migration/count evidence is still pending for this new snapshot.
