package com.skillforge.career.dto;

import java.time.Instant;
import java.util.UUID;

public record MockInterviewResponse(
        UUID id,
        String studentEmail,
        String topic,
        Instant scheduledTime,
        String status,
        String feedback,
        int score,
        Instant createdAt
) {
}
