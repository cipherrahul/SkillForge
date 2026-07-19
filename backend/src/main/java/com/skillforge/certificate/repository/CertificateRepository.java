package com.skillforge.certificate.repository;

import com.skillforge.certificate.entity.CertificateEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CertificateRepository extends JpaRepository<CertificateEntity, UUID> {
    Optional<CertificateEntity> findByEnrollmentId(UUID enrollmentId);
    Optional<CertificateEntity> findByVerificationCode(String verificationCode);
}
