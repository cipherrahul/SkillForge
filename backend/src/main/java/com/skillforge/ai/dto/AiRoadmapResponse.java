package com.skillforge.ai.dto;

import java.time.Instant;
import java.util.UUID;

public record AiRoadmapResponse(
        UUID id,
        String userEmail,
        String topic,
        String roadmapJson,
        Instant createdAt
) {
}
