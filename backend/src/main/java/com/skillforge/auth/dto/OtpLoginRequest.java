package com.skillforge.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record OtpLoginRequest(@NotBlank(message = "Email is required") String email,
                              @NotBlank(message = "OTP is required") String otp) {
}
