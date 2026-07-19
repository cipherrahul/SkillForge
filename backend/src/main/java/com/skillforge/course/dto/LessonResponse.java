package com.skillforge.course.dto;

import java.util.UUID;

public record LessonResponse(
        UUID id,
        String title,
        String description,
        String videoUrl,
        String pdfUrl,
        int durationMinutes,
        boolean isPreview,
        int sortOrder
) {
}
