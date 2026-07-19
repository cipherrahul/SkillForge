package com.skillforge.mobile.dto;

import java.time.Instant;
import java.util.List;

public record StudentMobileDashboard(
        List<String> enrolledCourses,
        String nextLiveClassTitle,
        Instant nextLiveClassTime,
        long unreadNotificationsCount,
        int statsXp
) {
}
