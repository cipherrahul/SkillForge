package com.skillforge.certificate.dto;

import java.time.Instant;
import java.util.UUID;

public record CertificateResponse(
        UUID id,
        UUID enrollmentId,
        String userEmail,
        UUID courseId,
        String courseTitle,
        String recipientName,
        String certificateUrl,
        String verificationCode,
        Instant issuedAt
) {
}
