package com.englishspeaking.ai.health.dto;

/**
 * Public, sanitized health response.
 * Strictly aligned to docs/API_CONTRACT.yaml (#/components/schemas/Health).
 * Contains only the required 'status' property, respecting additionalProperties: false.
 */
public record HealthResponse(
        String status
) {
    public static HealthResponse up() {
        return new HealthResponse("UP");
    }
}
