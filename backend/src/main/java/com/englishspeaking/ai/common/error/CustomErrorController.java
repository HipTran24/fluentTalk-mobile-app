package com.englishspeaking.ai.common.error;

import com.englishspeaking.ai.common.filter.RequestIdFilter;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.webmvc.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Fallback error controller ensuring even container-level errors (/error) return
 * the standard ApiErrorResponse shape.
 */
@RestController
public class CustomErrorController implements ErrorController {

    @RequestMapping("/error")
    public ResponseEntity<ApiErrorResponse> handleError(HttpServletRequest request) {
        String requestId = RequestIdFilter.getRequestId(request);

        Object statusCodeObj = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
        int statusCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
        if (statusCodeObj instanceof Integer code) {
            statusCode = code;
        }

        HttpStatus status = HttpStatus.resolve(statusCode);
        if (status == null) {
            status = HttpStatus.INTERNAL_SERVER_ERROR;
        }

        Object messageObj = request.getAttribute(RequestDispatcher.ERROR_MESSAGE);
        String message = (messageObj instanceof String s && !s.isBlank())
                ? s
                : (status == HttpStatus.NOT_FOUND ? "Requested endpoint not found" : status.getReasonPhrase());

        Object pathObj = request.getAttribute(RequestDispatcher.ERROR_REQUEST_URI);
        String path = (pathObj instanceof String p) ? p : request.getRequestURI();

        String errorCode = switch (status) {
            case NOT_FOUND -> "NOT_FOUND";
            case BAD_REQUEST -> "BAD_REQUEST";
            case UNAUTHORIZED -> "UNAUTHENTICATED";
            case FORBIDDEN -> "FORBIDDEN";
            case METHOD_NOT_ALLOWED -> "METHOD_NOT_ALLOWED";
            default -> status.is4xxClientError() ? "CLIENT_ERROR" : "INTERNAL_SERVER_ERROR";
        };

        return ResponseEntity
                .status(status)
                .body(new ApiErrorResponse(
                        errorCode,
                        message,
                        path != null ? Map.of("path", path) : Map.of(),
                        requestId
                ));
    }
}
