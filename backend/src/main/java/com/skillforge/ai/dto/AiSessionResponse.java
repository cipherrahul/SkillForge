package com.skillforge.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record AiSessionResponse(
        UUID id,
        String userEmail,
        UUID lessonId,
        String type,
        String context,
        Instant createdAt
) {
}
