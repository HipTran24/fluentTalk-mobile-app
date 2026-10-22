package com.englishspeaking.ai.profile.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * DTO strictly conforming to docs/API_CONTRACT.yaml (#/components/schemas/ProfileUpdate).
 */
public record ProfileUpdateRequest(
        @Size(min = 1, max = 80, message = "displayName length must be between 1 and 80")
        String displayName,

        @Pattern(regexp = "^(A0|A1|A2|B1|B2|C1|C2)$", message = "level must be one of A0, A1, A2, B1, B2, C1, C2")
        String level,

        @Size(max = 100, message = "goal must be at most 100 characters")
        String goal,

        @Min(value = 5, message = "dailyMinutes must be at least 5")
        @Max(value = 60, message = "dailyMinutes must be at most 60")
        Integer dailyMinutes,

        Boolean onboarded
) {}
