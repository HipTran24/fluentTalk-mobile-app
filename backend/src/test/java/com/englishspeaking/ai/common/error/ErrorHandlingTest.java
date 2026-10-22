package com.englishspeaking.ai.common.error;

import com.englishspeaking.ai.common.filter.RequestIdFilter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ErrorHandlingTest {

    private MockMvc mockMvc;

    @RestController
    @RequestMapping("/test")
    static class DummyTestController {
        @GetMapping("/api-exception")
        public void throwApiException() {
            throw new ApiException("QUOTA_EXCEEDED", "Daily conversation quota reached", HttpStatus.TOO_MANY_REQUESTS, Map.of("limit", 100));
        }

        @PostMapping("/validate")
        public void validatePayload(@Valid @RequestBody DummyPayload payload) {
            // No-op
        }

        @GetMapping("/unhandled")
        public void throwUnhandled() {
            throw new RuntimeException("Unexpected internal failure");
        }
    }

    record DummyPayload(@NotBlank(message = "Text cannot be blank") String text) {}

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new DummyTestController())
                .addFilters(new RequestIdFilter())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("ApiException is translated to standard UTC JSON error shape")
    void apiException_shouldReturnStandardErrorJson() throws Exception {
        String testRequestId = "req-api-err-111";

        mockMvc.perform(get("/test/api-exception")
                        .header("X-Request-Id", testRequestId))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("X-Request-Id", testRequestId))
                .andExpect(jsonPath("$.code", is("QUOTA_EXCEEDED")))
                .andExpect(jsonPath("$.message", is("Daily conversation quota reached")))
                .andExpect(jsonPath("$.details.limit", is(100)))
                .andExpect(jsonPath("$.requestId", is(testRequestId)))
                .andExpect(jsonPath("$.timestamp", matchesPattern("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")));
    }

    @Test
    @DisplayName("Validation failure is translated to standard UTC JSON error shape with field details")
    void validationFailure_shouldReturnStandardErrorJson() throws Exception {
        String testRequestId = "req-val-err-222";

        mockMvc.perform(post("/test/validate")
                        .header("X-Request-Id", testRequestId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(header().string("X-Request-Id", testRequestId))
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.details.fields.text", notNullValue()))
                .andExpect(jsonPath("$.requestId", is(testRequestId)))
                .andExpect(jsonPath("$.timestamp", matchesPattern("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")));
    }

    @Test
    @DisplayName("Method Not Allowed (405) returns standard UTC JSON error shape")
    void methodNotAllowed_shouldReturnStandardErrorJson() throws Exception {
        String testRequestId = "req-405-test-333";

        mockMvc.perform(post("/test/api-exception")
                        .header("X-Request-Id", testRequestId))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(header().string("X-Request-Id", testRequestId))
                .andExpect(jsonPath("$.code", is("METHOD_NOT_ALLOWED")))
                .andExpect(jsonPath("$.requestId", is(testRequestId)))
                .andExpect(jsonPath("$.timestamp", matchesPattern("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")));
    }

    @Test
    @DisplayName("Unhandled Exception returns 500 INTERNAL_SERVER_ERROR with sanitized message")
    void unhandledException_shouldReturnSanitized500() throws Exception {
        String testRequestId = "req-500-test-444";

        mockMvc.perform(get("/test/unhandled")
                        .header("X-Request-Id", testRequestId))
                .andExpect(status().isInternalServerError())
                .andExpect(header().string("X-Request-Id", testRequestId))
                .andExpect(jsonPath("$.code", is("INTERNAL_SERVER_ERROR")))
                .andExpect(jsonPath("$.requestId", is(testRequestId)))
                .andExpect(jsonPath("$.timestamp", matchesPattern("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")));
    }
}
