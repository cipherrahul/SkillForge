package com.skillforge.community.dto;

import java.time.Instant;
import java.util.UUID;

public record StudentGroupResponse(
        UUID id,
        String name,
        String description,
        int memberCount,
        Instant createdAt
) {
}
