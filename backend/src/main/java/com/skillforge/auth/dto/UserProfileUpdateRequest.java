package com.skillforge.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record UserProfileUpdateRequest(@NotBlank(message = "Full name is required") String fullName) {
}
