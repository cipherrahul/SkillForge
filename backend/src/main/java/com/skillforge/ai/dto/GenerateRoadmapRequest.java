package com.skillforge.ai.dto;

import jakarta.validation.constraints.NotBlank;

public record GenerateRoadmapRequest(
        @NotBlank(message = "Topic is required")
        String topic
) {
}
