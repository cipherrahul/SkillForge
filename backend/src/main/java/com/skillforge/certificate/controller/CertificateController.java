package com.skillforge.certificate.controller;

import com.skillforge.certificate.dto.CertificateResponse;
import com.skillforge.certificate.entity.CertificateEntity;
import com.skillforge.certificate.repository.CertificateRepository;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.common.exception.ResourceNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
public class CertificateController {
    private final CertificateRepository certificateRepository;

    public CertificateController(CertificateRepository certificateRepository) {
        this.certificateRepository = certificateRepository;
    }

    @GetMapping("/api/v1/certificates/enrollments/{enrollmentId}")
    public ResponseEntity<ApiResponse<CertificateResponse>> getCertificateByEnrollment(@PathVariable String enrollmentId,
                                                                                      HttpServletRequest servletRequest) {
        CertificateEntity certificate = certificateRepository.findByEnrollmentId(UUID.fromString(enrollmentId))
                .orElseThrow(() -> new ResourceNotFoundException("Certificate not found for the given enrollment"));
        CertificateResponse response = mapToResponse(certificate);
        return ResponseEntity.ok(ApiResponse.success("Certificate loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/certificates/verify/{verificationCode}")
    public ResponseEntity<ApiResponse<CertificateResponse>> verifyCertificate(@PathVariable String verificationCode,
                                                                              HttpServletRequest servletRequest) {
        CertificateEntity certificate = certificateRepository.findByVerificationCode(verificationCode.toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("Certificate with the given verification code is invalid"));
        CertificateResponse response = mapToResponse(certificate);
        return ResponseEntity.ok(ApiResponse.success("Certificate is valid", response, servletRequest.getRequestURI()));
    }

    private CertificateResponse mapToResponse(CertificateEntity c) {
        return new CertificateResponse(
                c.getId(),
                c.getEnrollmentId(),
                c.getUserEmail(),
                c.getCourseId(),
                c.getCourseTitle(),
                c.getRecipientName(),
                c.getCertificateUrl(),
                c.getVerificationCode(),
                c.getIssuedAt()
        );
    }
}
