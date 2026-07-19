package com.skillforge.liveclass.dto;

import com.skillforge.liveclass.entity.MentoringStatus;

import java.time.Instant;
import java.util.UUID;

public record MentoringResponse(
        UUID id,
        String instructorEmail,
        String studentEmail,
        String title,
        String description,
        Instant startTime,
        Instant endTime,
        MentoringStatus status,
        String meetingUrl,
        String feedback
) {
}
