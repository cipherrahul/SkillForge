package com.skillforge.learning.dto;

import java.time.Instant;
import java.util.UUID;

public record BookmarkResponse(
        UUID id,
        UUID lessonId,
        String title,
        int videoTimestampSeconds,
        Instant createdAt
) {
}
