package com.skillforge.course.dto;

import java.time.Instant;
import java.util.UUID;

public record ReviewResponse(
        UUID id,
        UUID courseId,
        String userEmail,
        String userFullName,
        int rating,
        String comment,
        Instant createdAt
) {
}
