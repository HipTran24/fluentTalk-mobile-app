package com.englishspeaking.ai.health;

import com.englishspeaking.ai.common.error.GlobalExceptionHandler;
import com.englishspeaking.ai.common.filter.RequestIdFilter;
import com.englishspeaking.ai.health.controller.HealthController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class HealthEndpointTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        HealthController controller = new HealthController();
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .addFilters(new RequestIdFilter())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/health returns 200 with sanitized health status and request ID aligned to API_CONTRACT")
    void getHealth_shouldReturnSanitizedStatusAndRequestId() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status", is("UP")))
                // Ensure no sensitive or unexpected fields leaked (conforms to additionalProperties: false)
                .andExpect(jsonPath("$.version").doesNotExist())
                .andExpect(jsonPath("$.database").doesNotExist())
                .andExpect(jsonPath("$.supabase").doesNotExist())
                .andExpect(jsonPath("$.gemini").doesNotExist())
                .andExpect(jsonPath("$.apiKey").doesNotExist())
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    @Test
    @DisplayName("GET /api/v1/health propagates incoming X-Request-Id")
    void getHealth_shouldPropagateExistingRequestId() throws Exception {
        String testRequestId = "test-corr-id-12345";

        mockMvc.perform(get("/api/v1/health")
                        .header("X-Request-Id", testRequestId))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Request-Id", testRequestId))
                .andExpect(jsonPath("$.status", is("UP")));
    }
}
