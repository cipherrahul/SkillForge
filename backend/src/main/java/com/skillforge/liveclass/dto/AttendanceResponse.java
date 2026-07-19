package com.skillforge.liveclass.dto;

import java.time.Instant;
import java.util.UUID;

public record AttendanceResponse(
        UUID id,
        UUID liveSessionId,
        String userEmail,
        Instant joinedAt,
        Instant leftAt,
        int durationMinutes
) {
}
