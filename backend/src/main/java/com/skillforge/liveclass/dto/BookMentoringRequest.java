package com.skillforge.liveclass.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record BookMentoringRequest(
        @NotBlank(message = "Instructor email is required")
        @Email(message = "Invalid email format")
        String instructorEmail,

        @NotBlank(message = "Title is required")
        String title,

        String description,

        @NotNull(message = "Start time is required")
        Instant startTime,

        @NotNull(message = "End time is required")
        Instant endTime
) {
}
