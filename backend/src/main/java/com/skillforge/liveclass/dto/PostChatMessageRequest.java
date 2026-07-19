package com.skillforge.liveclass.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PostChatMessageRequest(
        @NotBlank(message = "Message content cannot be blank")
        @Size(max = 2000, message = "Message exceeds character limit")
        String message
) {
}
