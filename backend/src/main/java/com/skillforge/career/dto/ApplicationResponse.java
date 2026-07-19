package com.skillforge.career.dto;

import java.time.Instant;
import java.util.UUID;

public record ApplicationResponse(
        UUID id,
        UUID jobId,
        String jobTitle,
        String companyName,
        String studentEmail,
        String resumeUrl,
        String status,
        String coverLetter,
        Instant createdAt
) {
}
