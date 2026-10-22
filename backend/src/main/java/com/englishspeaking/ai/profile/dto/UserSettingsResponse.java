package com.englishspeaking.ai.profile.dto;

import com.englishspeaking.ai.profile.domain.UserSettings;

import java.util.UUID;

public record UserSettingsResponse(
        UUID userId,
        boolean notificationsEnabled,
        int audioRetentionDays
) {
    public static UserSettingsResponse from(UserSettings settings) {
        return new UserSettingsResponse(
                settings.getUserId(),
                settings.isNotificationsEnabled(),
                settings.getAudioRetentionDays()
        );
    }
}
