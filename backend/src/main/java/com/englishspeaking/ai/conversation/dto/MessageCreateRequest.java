package com.englishspeaking.ai.conversation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MessageCreateRequest(
        @NotBlank(message = "Message text cannot be blank")
        @Size(min = 1, max = 4000, message = "Message text must be between 1 and 4000 characters")
        String text
) {}
