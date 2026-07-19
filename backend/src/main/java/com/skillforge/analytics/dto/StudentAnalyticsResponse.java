package com.skillforge.analytics.dto;

public record StudentAnalyticsResponse(
        long totalRegisteredStudents,
        long activeStudentsLast30Days,
        double averageProgressPercent,
        long completedCoursesCount
) {
}
