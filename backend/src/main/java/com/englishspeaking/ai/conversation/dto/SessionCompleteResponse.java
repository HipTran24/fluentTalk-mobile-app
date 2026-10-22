package com.englishspeaking.ai.conversation.dto;

import java.util.UUID;

public record SessionCompleteResponse(
        String status,
        UUID sessionId
) {}
