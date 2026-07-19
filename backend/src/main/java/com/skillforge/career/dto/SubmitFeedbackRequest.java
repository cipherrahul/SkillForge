package com.skillforge.career.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record SubmitFeedbackRequest(
        @NotBlank(message = "Feedback is required")
        String feedback,

        @Min(value = 0, message = "Score cannot be less than 0")
        @Max(value = 100, message = "Score cannot exceed 100")
        int score
) {
}
