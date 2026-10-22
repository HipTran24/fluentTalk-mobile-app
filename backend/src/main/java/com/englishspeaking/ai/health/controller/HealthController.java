package com.englishspeaking.ai.health.controller;

import com.englishspeaking.ai.health.dto.HealthResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    /**
     * Sanitized public health endpoint.
     * Strictly aligned to docs/API_CONTRACT.yaml GET /health.
     * Excludes environment variables, database strings, or internal infrastructure details.
     */
    @GetMapping
    public ResponseEntity<HealthResponse> getHealth() {
        return ResponseEntity.ok(HealthResponse.up());
    }
}
