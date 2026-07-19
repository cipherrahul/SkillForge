package com.skillforge.community.dto;

import java.util.UUID;

public record LeaderboardResponse(
        UUID id,
        String userEmail,
        String userFullName,
        int xpPoints,
        int rank
) {
}
