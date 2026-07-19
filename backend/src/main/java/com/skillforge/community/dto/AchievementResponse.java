package com.skillforge.community.dto;

import java.time.Instant;
import java.util.UUID;

public record AchievementResponse(
        UUID id,
        String userEmail,
        String title,
        String description,
        String badgeType,
        Instant unlockedAt
) {
}
