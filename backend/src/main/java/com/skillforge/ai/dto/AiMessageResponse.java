package com.skillforge.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record AiMessageResponse(
        UUID id,
        UUID sessionId,
        String sender,
        String message,
        Instant timestamp
) {
}
