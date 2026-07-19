package com.skillforge.analytics.dto;

public record PlatformKpisResponse(
        long totalUsers,
        long monthlyActiveUsers,
        double studentEngagementHours,
        double courseSatisfactionRate
) {
}
