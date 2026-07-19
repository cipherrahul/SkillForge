package com.skillforge.course.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateSectionRequest(@NotBlank(message = "Section title is required") String title,
                                   String description) {
}
