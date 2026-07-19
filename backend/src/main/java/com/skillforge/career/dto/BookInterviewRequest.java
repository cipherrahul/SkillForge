package com.skillforge.career.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record BookInterviewRequest(
        @NotBlank(message = "Topic is required")
        String topic,

        @NotNull(message = "Scheduled time is required")
        Instant scheduledTime
) {
}
