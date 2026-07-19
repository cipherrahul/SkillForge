package com.skillforge.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record GoogleLoginRequest(@NotBlank(message = "Email is required") @Email(message = "Email must be valid") String email,
                                 @NotBlank(message = "Full name is required") String fullName) {
}
