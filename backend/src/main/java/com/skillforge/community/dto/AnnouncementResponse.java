package com.skillforge.community.dto;

import java.time.Instant;
import java.util.UUID;

public record AnnouncementResponse(
        UUID id,
        UUID courseId,
        String instructorEmail,
        String title,
        String content,
        Instant createdAt
) {
}
