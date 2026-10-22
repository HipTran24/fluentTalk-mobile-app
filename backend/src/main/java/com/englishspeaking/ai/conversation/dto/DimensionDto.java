package com.englishspeaking.ai.conversation.dto;

import java.util.List;

public record DimensionDto(
        String dimension,
        Double estimatedBand,
        Double confidence,
        List<String> evidence,
        String scorerProvider,
        String scorerVersion
) {}
