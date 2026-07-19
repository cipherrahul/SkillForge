package com.skillforge.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(
        @NotBlank(message = "Message content is required")
        @Size(max = 4000, message = "Message exceeds maximum length")
        String message
) {
}
