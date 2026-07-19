package com.skillforge.community.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public record CreatePostRequest(
        UUID courseId, // optional

        @NotBlank(message = "Title is required")
        String title,

        @NotBlank(message = "Content is required")
        String content,

        boolean isQuestion,

        String category // e.g. GENERAL, PROGRAMMING
) {
}
