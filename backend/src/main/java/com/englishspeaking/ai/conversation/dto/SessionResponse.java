package com.englishspeaking.ai.conversation.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record SessionResponse(
        UUID id,
        UUID scenarioId,
        String mode,
        String status,
        Instant startedAt,
        Instant endedAt,
        int durationSeconds,
        List<MessageResponse> messages
) {}
