package com.skillforge.liveclass.repository;

import com.skillforge.liveclass.entity.MentoringSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MentoringSessionRepository extends JpaRepository<MentoringSessionEntity, UUID> {
    List<MentoringSessionEntity> findByStudentEmail(String studentEmail);
    List<MentoringSessionEntity> findByInstructorEmail(String instructorEmail);
    List<MentoringSessionEntity> findByStudentEmailOrInstructorEmail(String studentEmail, String instructorEmail);
}
