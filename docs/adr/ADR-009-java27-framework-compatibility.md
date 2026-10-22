# ADR 009 Framework compatibility for Java 27

Date: 2026-10-21. Status: accepted for local implementation; release maturity gate remains open.

The user explicitly requests Java 27. OpenJDK 27.0.1 GA macOS ARM64 is installed in a task-isolated cache after official SHA256 verification. JAVA_HOME is /Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home. No global Java selection changed.

Measured first attempt: Spring Boot 3.4.2 on this JDK compiles Java 27 source but context tests fail with unsupported class file major version 71 in Spring ASM. Compiling --release 26 under JDK 27 would not satisfy this execution plan's Java 27 bytecode target and must not be reported as success.

Official pages retrieved 2026-10-21:
- https://docs.spring.io/spring-boot/3.5/system-requirements.html lists Boot 3.5.16 through Java 25.
- https://docs.spring.io/spring-boot/system-requirements.html lists stable Boot 4.1.1 through Java 26.
- https://docs.spring.io/spring-boot/4.2-SNAPSHOT/system-requirements.html explicitly lists Java 27 with Spring Framework 7.1 and marks the release line under development.
- Maven Central metadata contains fixed 4.2.0-M2 / Spring 7.1.0-M2 milestones.

Decision: retain Java 27 source/release/runtime and allow a fixed Spring Boot 4.2.0-M2 milestone if a stable baseline cannot pass the compatibility gate. This changes baseline ADR-002 Spring Boot 3.x as a necessary consequence of the user's requested Java version, rather than silently changing Java target. Do not use unpinned snapshots or isolated ASM replacement as a shortcut. Record actual selected versions and full test results. Do not call a preview framework a supported stable production stack. Production acceptance requires stable Java-27-compatible framework support or an explicit later product decision with measured evidence.

Measured outcome at16:43: selected Boot4.2.0-M2; Java27.0.1 context/health/error/config tests12/12 pass, verify packages executable JAR, application class major71, no classformat-ignore workaround. Root launched that JAR against fresh PostgreSQL17.11 and health returned UP. This establishes local runtime compatibility for the tested foundation, not blanket dependency compatibility or stable production support.
