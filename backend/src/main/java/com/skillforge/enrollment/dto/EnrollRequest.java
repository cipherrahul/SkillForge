package com.skillforge.enrollment.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record EnrollRequest(
        @NotNull(message = "Course ID is required")
        UUID courseId
) {
}
