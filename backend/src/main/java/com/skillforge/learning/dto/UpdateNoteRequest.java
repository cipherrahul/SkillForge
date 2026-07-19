package com.skillforge.learning.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateNoteRequest(
        @NotBlank(message = "Content is required")
        String content
) {
}
