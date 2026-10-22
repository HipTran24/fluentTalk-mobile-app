# ADR 008 Java 27 and four hour execution amendment

Date: 2026-10-21. Status: user-requested target; runtime compatibility gate unresolved.

The human explicitly requests Java 27 and four-hour execution in eight stages. Amend baseline ADR-002 Java 21 to Java 27 for backend only. Keep Flutter/Dart Android-first and Supabase/Gemini architecture. Android Gradle toolchain remains independently selected for supported builds.

Installed Java versions are 19,21,23,25,26; no 27 at initial inspection. Official Spring Boot stable system requirements fetched today advertise Java compatibility through 26 (https://docs.spring.io/spring-boot/system-requirements.html). Java 27 source https://jdk.java.net/27/ returned 403 to web tooling. Verify official available artifacts and checksum before using a locally isolated JDK. Do not change global Java settings. Build and tests on exact JDK 27 are needed; compilation on another JDK is not equivalent. Record framework choice and actual compatibility tests before acceptance. Do not silently replace requested Java version or claim supported production runtime without evidence.

The four-hour plan is an implementation timebox. Appendix D spans 24–28 weeks and explicitly prohibits promises of production completeness when scope cannot be verified. Full requirements remain in the backlog with release gates. Zero defects for every possible bug cannot be guaranteed; reliability means tested recovery, resource cleanup, isolation, observability and honest residual risk.

Temporarily keep Flutter at repository root, add backend/docs/infra there, to preserve current IDE paths; defer ADR-006 mobile/ relocation until no editor is concurrently working. Do not create nested Git repositories or lose existing changes.
