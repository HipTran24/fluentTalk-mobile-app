package com.englishspeaking.ai.conversation.dto;

public record TurnResultResponse(
        MessageResponse userMessage,
        MessageResponse aiMessage,
        String requestId
) {}
