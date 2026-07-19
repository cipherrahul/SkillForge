package com.skillforge.auth.dto;

import com.skillforge.auth.entity.Role;

import java.time.Instant;
import java.util.UUID;

public record UserProfileResponse(UUID id, String email, String fullName, Role role, Instant createdAt) {
}
