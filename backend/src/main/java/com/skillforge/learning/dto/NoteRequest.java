package com.skillforge.learning.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record NoteRequest(
        @NotNull(message = "Lesson ID is required")
        UUID lessonId,

        @NotBlank(message = "Content is required")
        String content,

        @NotNull(message = "Video timestamp is required")
        @Min(value = 0, message = "Timestamp cannot be negative")
        Integer videoTimestampSeconds
) {
}
