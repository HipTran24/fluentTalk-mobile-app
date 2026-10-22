package com.englishspeaking.ai.conversation.dto;

import java.util.List;
import java.util.UUID;

public record FeedbackResponse(
        UUID id,
        UUID sessionId,
        String rubricVersion,
        String status,
        String summaryVi,
        List<DimensionDto> dimensions,
        Double overallEstimatedBand,
        List<String> limitations,
        List<Object> corrections,
        String modelId,
        String promptVersion,
        String inputCompleteness,
        List<UUID> sourceMessageIds
) {}
