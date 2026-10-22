package com.englishspeaking.ai.curriculum.dto;

import java.util.List;
import java.util.UUID;

public record ScenarioDto(
        UUID id,
        UUID topicId,
        String level,
        String title,
        String description,
        String roleAi,
        String roleUser,
        List<String> learningObjectives,
        int estimatedMinutes,
        List<String> samplePhrases,
        List<VocabularyItemDto> vocabularyPreview,
        boolean active
) {}
