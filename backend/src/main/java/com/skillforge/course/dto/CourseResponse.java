package com.skillforge.course.dto;

import java.util.List;
import java.util.UUID;

public record CourseResponse(
        UUID id,
        String title,
        String description,
        double price,
        int durationHours,
        String difficulty,
        String categorySlug,
        String instructorEmail,
        String instructorName,
        String thumbnailUrl,
        boolean published,
        double averageRating,
        int totalReviews,
        int enrolledCount,
        List<SectionResponse> sections
) {
}
