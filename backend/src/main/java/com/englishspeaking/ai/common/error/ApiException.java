package com.englishspeaking.ai.common.error;

import org.springframework.http.HttpStatus;

import java.util.Collections;
import java.util.Map;

/**
 * Base application exception for typed API errors.
 */
public class ApiException extends RuntimeException {

    private final String code;
    private final HttpStatus status;
    private final Map<String, Object> details;

    public ApiException(String code, String message, HttpStatus status) {
        this(code, message, status, Collections.emptyMap());
    }

    public ApiException(String code, String message, HttpStatus status, Map<String, Object> details) {
        super(message);
        this.code = code;
        this.status = status;
        this.details = details != null ? details : Collections.emptyMap();
    }

    public String getCode() {
        return code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public Map<String, Object> getDetails() {
        return details;
    }
}
