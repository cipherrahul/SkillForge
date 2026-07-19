package com.skillforge.certificate.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.certificate.entity.CertificateEntity;
import com.skillforge.certificate.repository.CertificateRepository;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.storage.service.StorageService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class CertificateService {
    private final CertificateRepository certificateRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final StorageService storageService;

    public CertificateService(CertificateRepository certificateRepository,
                              UserRepository userRepository,
                              CourseRepository courseRepository,
                              StorageService storageService) {
        this.certificateRepository = certificateRepository;
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.storageService = storageService;
    }

    @Transactional
    public void generateCertificate(EnrollmentEntity enrollment) {
        if (certificateRepository.findByEnrollmentId(enrollment.getId()).isPresent()) {
            return; // Already generated
        }

        UserEntity user = userRepository.findByEmail(enrollment.getUserEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        CourseEntity course = courseRepository.findById(enrollment.getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        String verificationCode = UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase();

        // Format certificate content
        String dateStr = DateTimeFormatter.ISO_INSTANT.format(Instant.now());
        String certText = """
                ==================================================
                              SKILLFORGE PLATFORM
                              CERTIFICATE OF COMPLETION
                ==================================================
                
                This is to certify that
                
                              %s
                
                has successfully completed the course
                
                              %s
                
                Issued on: %s
                Verification Code: %s
                
                Verify this certificate at:
                /api/v1/certificates/verify/%s
                
                ==================================================
                """.formatted(user.getFullName(), course.getTitle(), dateStr, verificationCode, verificationCode);

        // Store file
        String filename = "certificate_" + enrollment.getId() + ".txt";
        String certificateUrl = storageService.storeBytes(certText.getBytes(), filename);

        // Save certificate entity
        CertificateEntity certificate = new CertificateEntity();
        certificate.setEnrollmentId(enrollment.getId());
        certificate.setUserEmail(user.getEmail());
        certificate.setCourseId(course.getId());
        certificate.setCourseTitle(course.getTitle());
        certificate.setRecipientName(user.getFullName());
        certificate.setCertificateUrl(certificateUrl);
        certificate.setVerificationCode(verificationCode);
        certificate.setIssuedAt(Instant.now());

        certificateRepository.save(certificate);
    }
}
