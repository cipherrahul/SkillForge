package com.skillforge.mobile.dto;

import com.skillforge.course.dto.CourseResponse;

import java.time.Instant;
import java.util.List;

public record StudentMobileDashboard(
        List<String> enrolledCourses,
        String nextLiveClassTitle,
        Instant nextLiveClassTime,
        long unreadNotificationsCount,
        int statsXp,
        List<CourseResponse> recentCourses
) {
}
