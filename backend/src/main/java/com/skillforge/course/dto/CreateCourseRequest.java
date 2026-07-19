package com.skillforge.course.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record CreateCourseRequest(
        @NotBlank(message = "Course title is required") String title,
        @NotBlank(message = "Course description is required") String description,
        @Positive(message = "Price must be positive") double price,
        @Positive(message = "Duration must be positive") int durationHours,
        @NotBlank(message = "Difficulty is required") String difficulty,
        @NotBlank(message = "Category slug is required") String categorySlug,
        String thumbnailUrl,
        boolean published
) {
}
