package com.skillforge.liveclass.dto;

import com.skillforge.liveclass.entity.LiveSessionStatus;
import com.skillforge.liveclass.entity.LiveSessionType;

import java.time.Instant;
import java.util.UUID;

public record LiveSessionResponse(
        UUID id,
        UUID courseId,
        String title,
        String description,
        String instructorEmail,
        Instant startTime,
        Instant endTime,
        LiveSessionType type,
        LiveSessionStatus status,
        String meetingUrl,
        String recordingUrl
) {
}
