package com.englishspeaking.ai.conversation.dto;

import java.util.UUID;

public record SessionCreateRequest(
        UUID scenarioId,
        String mode,
        String level
) {}
