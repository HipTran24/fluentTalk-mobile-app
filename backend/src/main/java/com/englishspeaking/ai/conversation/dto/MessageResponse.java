package com.englishspeaking.ai.conversation.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record MessageResponse(
        UUID id,
        String role,
        String text,
        String audioUrl,
        int sequenceNo,
        Instant timestamp,
        List<String> usefulPhrases,
        List<String> suggestedFollowUps
) {}
