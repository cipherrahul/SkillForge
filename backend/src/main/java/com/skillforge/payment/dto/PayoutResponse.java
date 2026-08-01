package com.skillforge.payment.dto;

import java.time.Instant;
import java.util.UUID;

public record PayoutResponse(
        UUID id,
        String instructorEmail,
        double amount,
        String status,
        String method,
        Instant requestedAt
) {
}
