package com.skillforge.liveclass.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record ScheduleSessionRequest(
        @NotBlank(message = "Title is required")
        String title,

        String description,

        @NotNull(message = "Start time is required")
        Instant startTime,

        @NotNull(message = "End time is required")
        Instant endTime,

        @NotBlank(message = "Session type is required")
        String type // LIVE_CLASS or DOUBT_SESSION
) {
}
