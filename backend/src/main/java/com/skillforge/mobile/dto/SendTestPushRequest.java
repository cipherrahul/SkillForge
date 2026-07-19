package com.skillforge.mobile.dto;

import jakarta.validation.constraints.NotBlank;

public record SendTestPushRequest(
        @NotBlank(message = "Title is required")
        String title,

        @NotBlank(message = "Body is required")
        String body,

        String userEmail // optional, if null sends to all devices of active user
) {
}
