package com.skillforge.career.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateJobRequest(
        @NotBlank(message = "Job title is required")
        String title,

        @NotBlank(message = "Company name is required")
        String companyName,

        String location,

        @NotBlank(message = "Type (JOB or INTERNSHIP) is required")
        String type,

        @NotBlank(message = "Description is required")
        String description,

        String requirements,

        String salaryRange
) {
}
