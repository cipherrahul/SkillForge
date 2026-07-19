package com.skillforge.analytics.dto;

import java.util.UUID;

public record CoursePerformanceResponse(
        UUID courseId,
        String title,
        long enrolledCount,
        double averageRating,
        double completionRatePercent,
        double revenueGenerated
) {
}
