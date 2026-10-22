package com.englishspeaking.ai.common.error;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.Instant;
import java.util.Collections;
import java.util.Map;

/**
 * Standard JSON error response model.
 * Matches: {"code":"...","message":"...","details":{},"requestId":"...","timestamp":"..."}
 * Timestamp is serialized in UTC ISO-8601 format.
 */
public record ApiErrorResponse(
        String code,
        String message,
        Map<String, Object> details,
        String requestId,
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", timezone = "UTC")
        Instant timestamp
) {
    public ApiErrorResponse(String code, String message, Map<String, Object> details, String requestId) {
        this(code, message, details != null ? details : Collections.emptyMap(), requestId, Instant.now());
    }

    public static ApiErrorResponse of(String code, String message, String requestId) {
        return new ApiErrorResponse(code, message, Collections.emptyMap(), requestId, Instant.now());
    }

    public static ApiErrorResponse of(String code, String message, Map<String, Object> details, String requestId) {
        return new ApiErrorResponse(code, message, details != null ? details : Collections.emptyMap(), requestId, Instant.now());
    }
}
