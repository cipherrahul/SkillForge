package com.skillforge.enrollment.dto;

import java.time.Instant;
import java.util.UUID;

public record EnrollmentResponse(
        UUID id,
        UUID courseId,
        String courseTitle,
        double progressPercent,
        boolean completed,
        Instant enrolledAt,
        Instant completedAt
) {
}
