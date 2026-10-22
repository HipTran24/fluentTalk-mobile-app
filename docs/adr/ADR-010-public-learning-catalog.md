# ADR 010 Public active learning catalog

Date: 2026-10-21. Status: accepted for current local API contract.

The source baseline permits public SELECT of active learning content while all user records require ownership. The first executable OpenAPI mirror accidentally inherited bearer authentication for every path, while the implemented catalog exposes active content publicly. Resolve this contract mismatch explicitly: GET /topics, /scenarios and /scenarios/{id} are public, active-content-only endpoints. Their response DTOs exclude initial system prompt templates and user data. All profile, administrative and user-owned resources remain protected by verified JWT and authorization.

The mobile application's protected learning routes can still require login; this does not imply that reusable public catalog metadata is private. This decision does not weaken any IDOR or account isolation requirement. The API contract has been updated before client catalog wiring, which remains unfinished.
