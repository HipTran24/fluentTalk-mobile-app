package com.englishspeaking.ai.curriculum.dto;

import java.util.List;

public record PaginatedScenariosDto(
        List<ScenarioDto> items,
        int page,
        int size,
        boolean hasMore
) {}
