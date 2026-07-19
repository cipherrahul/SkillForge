package com.skillforge.auth.dto;

public record AuthResponse(String accessToken, String refreshToken, String role, String email) {
}
