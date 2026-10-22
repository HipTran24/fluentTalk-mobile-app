package com.englishspeaking.ai.common.error;

import com.englishspeaking.ai.common.filter.RequestIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler transforming exceptions into standard ApiErrorResponse.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiErrorResponse> handleApiException(ApiException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        log.warn("API Exception [requestId={}] code={} message={}", requestId, ex.getCode(), ex.getMessage());
        return ResponseEntity
                .status(ex.getStatus())
                .body(new ApiErrorResponse(ex.getCode(), ex.getMessage(), ex.getDetails(), requestId));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidationException(MethodArgumentNotValidException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        Map<String, Object> fieldErrors = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }

        log.warn("Validation failed [requestId={}]: {}", requestId, fieldErrors);
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(new ApiErrorResponse(
                        "VALIDATION_FAILED",
                        "Validation failed for one or more fields",
                        Map.of("fields", fieldErrors),
                        requestId
                ));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiErrorResponse> handleConstraintViolation(ConstraintViolationException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        Map<String, Object> violations = new HashMap<>();
        ex.getConstraintViolations().forEach(cv -> violations.put(cv.getPropertyPath().toString(), cv.getMessage()));

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(new ApiErrorResponse(
                        "VALIDATION_FAILED",
                        "Constraint violation",
                        Map.of("violations", violations),
                        requestId
                ));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNoResourceFound(NoResourceFoundException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(new ApiErrorResponse(
                        "NOT_FOUND",
                        "Resource not found: " + ex.getResourcePath(),
                        Map.of("resourcePath", ex.getResourcePath()),
                        requestId
                ));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiErrorResponse> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        return ResponseEntity
                .status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(new ApiErrorResponse(
                        "METHOD_NOT_ALLOWED",
                        "HTTP method " + ex.getMethod() + " is not supported for this endpoint",
                        Map.of("method", ex.getMethod()),
                        requestId
                ));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiErrorResponse> handleAuthenticationException(AuthenticationException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(new ApiErrorResponse(
                        "UNAUTHENTICATED",
                        "Full authentication is required to access this resource",
                        Map.of(),
                        requestId
                ));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiErrorResponse> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(new ApiErrorResponse(
                        "FORBIDDEN",
                        "Access is denied",
                        Map.of(),
                        requestId
                ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiErrorResponse> handleResponseStatus(ResponseStatusException ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        HttpStatus status = HttpStatus.resolve(ex.getStatusCode().value());
        if (status == null) status = HttpStatus.INTERNAL_SERVER_ERROR;

        return ResponseEntity
                .status(status)
                .body(new ApiErrorResponse(
                        status.name(),
                        ex.getReason() != null ? ex.getReason() : status.getReasonPhrase(),
                        Map.of(),
                        requestId
                ));
    }

    @ExceptionHandler({
            org.springframework.web.bind.MissingRequestHeaderException.class,
            org.springframework.web.bind.MissingServletRequestParameterException.class,
            org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class,
            org.springframework.http.converter.HttpMessageNotReadableException.class
    })
    public ResponseEntity<ApiErrorResponse> handleMalformedRequest(Exception ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ApiErrorResponse(
                "VALIDATION_FAILED", "Request headers, parameters or JSON body are invalid", Map.of(),
                RequestIdFilter.getRequestId(request)));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGenericException(Exception ex, HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);
        log.error("Unhandled exception [requestId={}]", requestId, ex);

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiErrorResponse(
                        "INTERNAL_SERVER_ERROR",
                        "An unexpected error occurred. Please contact support with the requestId.",
                        Map.of(),
                        requestId
                ));
    }
}
