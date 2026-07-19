package com.skillforge.career.dto;

public record PlacementAnalyticsResponse(
        long totalJobs,
        long totalInternships,
        long totalApplications,
        long totalShortlisted,
        double placementRatePercent
) {
}
