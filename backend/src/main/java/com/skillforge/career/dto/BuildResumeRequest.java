package com.skillforge.career.dto;

import jakarta.validation.constraints.NotBlank;

public record BuildResumeRequest(
        @NotBlank(message = "Full name is required")
        String fullName,

        String education,

        String experience,

        String skills,

        String projects
) {
}
