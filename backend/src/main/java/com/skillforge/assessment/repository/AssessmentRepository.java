package com.skillforge.assessment.repository;

import com.skillforge.assessment.entity.AssessmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AssessmentRepository extends JpaRepository<AssessmentEntity, UUID> {
    List<AssessmentEntity> findByCourseId(UUID courseId);
}
