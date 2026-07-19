package com.skillforge.enrollment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record UpdateProgressRequest(
        @NotNull(message = "Completed flag is required")
        Boolean completed,

        @NotNull(message = "Playback position is required")
        @Min(value = 0, message = "Playback position cannot be negative")
        Integer playbackPositionSeconds
) {
}
