package com.skillforge.auth.controller;

import com.skillforge.auth.dto.AuthResponse;
import com.skillforge.auth.dto.GoogleLoginRequest;
import com.skillforge.auth.dto.LoginRequest;
import com.skillforge.auth.dto.OtpLoginRequest;
import com.skillforge.auth.dto.OtpRequest;
import com.skillforge.auth.dto.PasswordChangeRequest;
import com.skillforge.auth.dto.PasswordResetConfirmRequest;
import com.skillforge.auth.dto.PasswordResetRequest;
import com.skillforge.auth.dto.RefreshTokenRequest;
import com.skillforge.auth.dto.RegisterRequest;
import com.skillforge.auth.dto.UserProfileResponse;
import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.service.AuthService;
import com.skillforge.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success("User registered successfully", authResponse, servletRequest.getRequestURI()));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Login successful", authResponse, servletRequest.getRequestURI()));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@Valid @RequestBody RefreshTokenRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.refresh(request);
        return ResponseEntity.ok(ApiResponse.success("Token refreshed successfully", authResponse, servletRequest.getRequestURI()));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> me(HttpServletRequest servletRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        UserEntity user = authService.getCurrentUser(email);
        UserProfileResponse profile = new UserProfileResponse(user.getId(), user.getEmail(), user.getFullName(), user.getRole(), user.getCreatedAt());
        return ResponseEntity.ok(ApiResponse.success("Profile loaded", profile, servletRequest.getRequestURI()));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(@Valid @RequestBody com.skillforge.auth.dto.UserProfileUpdateRequest request, HttpServletRequest servletRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        UserEntity user = authService.updateProfile(email, request);
        UserProfileResponse profile = new UserProfileResponse(user.getId(), user.getEmail(), user.getFullName(), user.getRole(), user.getCreatedAt());
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", profile, servletRequest.getRequestURI()));
    }

    @PostMapping("/otp/request")
    public ResponseEntity<ApiResponse<String>> requestOtp(@Valid @RequestBody OtpRequest request, HttpServletRequest servletRequest) {
        String message = authService.requestOtp(request);
        return ResponseEntity.ok(ApiResponse.success(message, message, servletRequest.getRequestURI()));
    }

    @PostMapping("/otp/login")
    public ResponseEntity<ApiResponse<AuthResponse>> otpLogin(@Valid @RequestBody OtpLoginRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.loginWithOtp(request);
        return ResponseEntity.ok(ApiResponse.success("OTP login successful", authResponse, servletRequest.getRequestURI()));
    }

    @PostMapping("/password/reset")
    public ResponseEntity<ApiResponse<String>> requestPasswordReset(@Valid @RequestBody PasswordResetRequest request, HttpServletRequest servletRequest) {
        String message = authService.requestPasswordReset(request);
        return ResponseEntity.ok(ApiResponse.success(message, message, servletRequest.getRequestURI()));
    }

    @PostMapping("/password/reset/confirm")
    public ResponseEntity<ApiResponse<AuthResponse>> confirmPasswordReset(@Valid @RequestBody PasswordResetConfirmRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.confirmPasswordReset(request);
        return ResponseEntity.ok(ApiResponse.success("Password reset successful", authResponse, servletRequest.getRequestURI()));
    }

    @PostMapping("/google/login")
    public ResponseEntity<ApiResponse<AuthResponse>> googleLogin(@Valid @RequestBody GoogleLoginRequest request, HttpServletRequest servletRequest) {
        AuthResponse authResponse = authService.googleLogin(request);
        return ResponseEntity.ok(ApiResponse.success("Google login successful", authResponse, servletRequest.getRequestURI()));
    }

    @PutMapping("/password")
    public ResponseEntity<ApiResponse<UserProfileResponse>> changePassword(@Valid @RequestBody PasswordChangeRequest request, HttpServletRequest servletRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        UserEntity user = authService.changePassword(email, request);
        UserProfileResponse profile = new UserProfileResponse(user.getId(), user.getEmail(), user.getFullName(), user.getRole(), user.getCreatedAt());
        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", profile, servletRequest.getRequestURI()));
    }
}
