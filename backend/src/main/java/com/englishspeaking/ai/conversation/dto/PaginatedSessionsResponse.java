package com.englishspeaking.ai.conversation.dto;

import java.util.List;

public record PaginatedSessionsResponse(
        List<SessionResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages,
        boolean hasMore
) {}
