package com.englishspeaking.ai.conversation.dto;

public record ProgressSummaryResponse(
        int totalSessions,
        int totalMinutes,
        String currentLevel,
        int currentStreakDays,
        Double averageBand
) {}
