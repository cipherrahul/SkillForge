package com.skillforge.playground.dto;

import jakarta.validation.constraints.NotBlank;

public record PlaygroundRequest(
        @NotBlank(message = "Language is required")
        String language,

        @NotBlank(message = "Code is required")
        String code,

        String input
) {
}
