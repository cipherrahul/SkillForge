package com.skillforge.mobile.dto;

public record InstructorMobileDashboard(
        long totalCoursesCreated,
        long activeStudentsCount,
        long pendingAssessmentsCount,
        double totalEarnedRevenue
) {
}
