package com.skillforge.enterprise.dto;

import jakarta.validation.constraints.NotBlank;

public record LogSystemEventRequest(
        @NotBlank(message = "Event type is required")
        String eventType,

        @NotBlank(message = "Severity is required")
        String severity,

        @NotBlank(message = "Details content is required")
        String details
) {
}
