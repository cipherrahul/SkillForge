package com.skillforge.enrollment.repository;

import com.skillforge.enrollment.entity.LessonProgressEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonProgressRepository extends JpaRepository<LessonProgressEntity, UUID> {
    Optional<LessonProgressEntity> findByEnrollmentIdAndLessonId(UUID enrollmentId, UUID lessonId);
}
