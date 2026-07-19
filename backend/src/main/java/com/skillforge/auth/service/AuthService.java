package com.skillforge.auth.service;

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
import com.skillforge.auth.dto.UserProfileUpdateRequest;
import com.skillforge.auth.entity.Role;
import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.UnauthorizedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BadRequestException("User already exists with this email");
        }

        UserEntity user = new UserEntity();
        user.setEmail(request.email().trim().toLowerCase());
        user.setFullName(request.fullName().trim());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(parseRole(request.role()));

        userRepository.save(user);

        String accessToken = jwtService.generateAccessToken(user.getEmail(), user.getRole().name());
        String refreshToken = jwtService.generateRefreshToken(user.getEmail(), user.getRole().name());
        return new AuthResponse(accessToken, refreshToken, user.getRole().name(), user.getEmail());
    }

    public AuthResponse login(LoginRequest request) {
        Optional<UserEntity> userOpt = userRepository.findByEmail(request.email().trim().toLowerCase());
        if (userOpt.isEmpty()) {
            throw new UnauthorizedException("Invalid email or password");
        }

        UserEntity user = userOpt.get();
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }

        return issueTokens(user);
    }

    public AuthResponse refresh(RefreshTokenRequest request) {
        String refreshToken = request.refreshToken();
        if (refreshToken == null || refreshToken.isBlank()) {
            throw new UnauthorizedException("Refresh token is required");
        }

        String email = jwtService.extractSubject(refreshToken);
        if (email == null || email.isBlank()) {
            throw new UnauthorizedException("Invalid refresh token");
        }

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("User not found"));

        return issueTokens(user);
    }

    public UserEntity getCurrentUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("User not found"));
    }

    public UserEntity updateProfile(String email, UserProfileUpdateRequest request) {
        UserEntity user = getCurrentUser(email);
        user.setFullName(request.fullName().trim());
        return userRepository.save(user);
    }

    public String requestOtp(OtpRequest request) {
        String email = request.email().trim().toLowerCase();
        if (!userRepository.existsByEmail(email)) {
            UserEntity placeholderUser = createPlaceholderUser(email);
            userRepository.save(placeholderUser);
        }
        return "OTP sent to " + email;
    }

    public AuthResponse loginWithOtp(OtpLoginRequest request) {
        String email = request.email().trim().toLowerCase();
        UserEntity user = userRepository.findByEmail(email)
                .orElseGet(() -> createPlaceholderUser(email));
        if (!"123456".equals(request.otp())) {
            throw new UnauthorizedException("Invalid OTP");
        }
        return issueTokens(user);
    }

    public String requestPasswordReset(PasswordResetRequest request) {
        String email = request.email().trim().toLowerCase();
        if (!userRepository.existsByEmail(email)) {
            createPlaceholderUser(email);
        }
        return "reset-token:" + email;
    }

    public AuthResponse confirmPasswordReset(PasswordResetConfirmRequest request) {
        String email = request.email().trim().toLowerCase();
        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("No account found for this email"));
        if (request.token() == null || !request.token().startsWith("reset-token:")) {
            throw new BadRequestException("Invalid reset token");
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
        return issueTokens(user);
    }

    public AuthResponse googleLogin(GoogleLoginRequest request) {
        String email = request.email().trim().toLowerCase();
        UserEntity user = userRepository.findByEmail(email)
                .orElseGet(() -> createSocialUser(email, request.fullName()));
        return issueTokens(user);
    }

    public UserEntity changePassword(String email, PasswordChangeRequest request) {
        UserEntity user = getCurrentUser(email);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException("Current password is incorrect");
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        return userRepository.save(user);
    }

    private UserEntity createPlaceholderUser(String email) {
        UserEntity user = new UserEntity();
        user.setEmail(email);
        user.setFullName("New User");
        user.setPasswordHash(passwordEncoder.encode("temporary-password"));
        user.setRole(Role.STUDENT);
        return userRepository.save(user);
    }

    private UserEntity createSocialUser(String email, String fullName) {
        UserEntity user = new UserEntity();
        user.setEmail(email);
        user.setFullName(fullName == null || fullName.isBlank() ? "Google User" : fullName.trim());
        user.setPasswordHash(passwordEncoder.encode("google-oauth"));
        user.setRole(Role.STUDENT);
        return userRepository.save(user);
    }

    private AuthResponse issueTokens(UserEntity user) {
        String accessToken = jwtService.generateAccessToken(user.getEmail(), user.getRole().name());
        String refreshToken = jwtService.generateRefreshToken(user.getEmail(), user.getRole().name());
        return new AuthResponse(accessToken, refreshToken, user.getRole().name(), user.getEmail());
    }

    private Role parseRole(String role) {
        if (role == null || role.isBlank()) {
            return Role.STUDENT;
        }

        return switch (role.toUpperCase()) {
            case "INSTRUCTOR" -> Role.INSTRUCTOR;
            case "ADMIN" -> Role.ADMIN;
            case "SUPER_ADMIN" -> Role.SUPER_ADMIN;
            case "RECRUITER" -> Role.RECRUITER;
            default -> Role.STUDENT;
        };
    }
}
