package com.skillforge.mobile.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterDeviceRequest(
        @NotBlank(message = "Device token is required")
        String deviceToken,

        @NotBlank(message = "OS Platform (ANDROID or IOS) is required")
        String osPlatform
) {
}
