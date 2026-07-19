package com.skillforge.enrollment.repository;

import com.skillforge.enrollment.entity.EnrollmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EnrollmentRepository extends JpaRepository<EnrollmentEntity, UUID> {
    List<EnrollmentEntity> findByUserEmail(String userEmail);
    Optional<EnrollmentEntity> findByUserEmailAndCourseId(String userEmail, UUID courseId);
    boolean existsByUserEmailAndCourseId(String userEmail, UUID courseId);
    List<EnrollmentEntity> findByCourseId(UUID courseId);
}
