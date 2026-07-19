package com.skillforge.assessment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record GradeSubmissionRequest(
        @NotNull(message = "Score is required")
        @Min(value = 0, message = "Score cannot be negative")
        Integer score,

        String feedback
) {
}
