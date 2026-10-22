package com.englishspeaking.ai.profile.dto;

import com.englishspeaking.ai.profile.domain.Profile;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO strictly conforming to docs/API_CONTRACT.yaml (#/components/schemas/Profile).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfileResponse(
        UUID id,
        String email,
        String displayName,
        String avatarUrl,
        String level,
        String goal,
        int dailyMinutes,
        boolean onboarded,
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", timezone = "UTC")
        Instant createdAt
) {
    public static ProfileResponse from(Profile profile) {
        return new ProfileResponse(
                profile.getId(),
                profile.getEmail(),
                profile.getDisplayName(),
                profile.getAvatarUrl(),
                profile.getLevel(),
                profile.getGoal(),
                profile.getDailyMinutes(),
                profile.isOnboarded(),
                profile.getCreatedAt()
        );
    }
}
