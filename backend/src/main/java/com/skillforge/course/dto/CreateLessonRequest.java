package com.skillforge.course.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record CreateLessonRequest(
        @NotBlank(message = "Lesson title is required") String title,
        String description,
        String videoUrl,
        String pdfUrl,
        @NotNull(message = "Duration is required") @PositiveOrZero(message = "Duration must be positive or zero") Integer durationMinutes,
        @NotNull(message = "isPreview flag is required") Boolean isPreview,
        @NotNull(message = "sortOrder is required") Integer sortOrder
) {
}
