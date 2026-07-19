package com.skillforge.analytics.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record LogActivityRequest(
        @NotBlank(message = "Action is required")
        String action, // e.g. LOGIN, WATCH_LESSON

        @Min(value = 1, message = "Duration must be at least 1 minute")
        int durationMinutes
) {
}
