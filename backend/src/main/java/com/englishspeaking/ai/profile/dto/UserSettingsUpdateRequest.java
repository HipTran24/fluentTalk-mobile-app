package com.englishspeaking.ai.profile.dto;

import jakarta.validation.constraints.Min;

public record UserSettingsUpdateRequest(
        Boolean notificationsEnabled,

        @Min(value = 0, message = "audioRetentionDays must be >= 0")
        Integer audioRetentionDays
) {}
