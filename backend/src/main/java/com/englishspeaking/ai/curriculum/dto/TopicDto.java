package com.englishspeaking.ai.curriculum.dto;

import java.util.UUID;

public record TopicDto(
        UUID id,
        String slug,
        String title
) {}
