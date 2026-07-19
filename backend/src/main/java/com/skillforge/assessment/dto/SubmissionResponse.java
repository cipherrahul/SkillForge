package com.skillforge.assessment.dto;

import java.time.Instant;
import java.util.UUID;

public record SubmissionResponse(
        UUID id,
        UUID assessmentId,
        String userEmail,
        int score,
        boolean passed,
        String feedback,
        boolean graded,
        Instant submittedAt,
        String fileUrl
) {
}
