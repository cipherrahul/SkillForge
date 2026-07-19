package com.skillforge.learning.dto;

import java.time.Instant;
import java.util.UUID;

public record NoteResponse(
        UUID id,
        UUID lessonId,
        String content,
        int videoTimestampSeconds,
        Instant createdAt,
        Instant updatedAt
) {
}
