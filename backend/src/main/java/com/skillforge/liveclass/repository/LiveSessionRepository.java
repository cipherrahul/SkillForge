package com.skillforge.liveclass.repository;

import com.skillforge.liveclass.entity.LiveSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LiveSessionRepository extends JpaRepository<LiveSessionEntity, UUID> {
    List<LiveSessionEntity> findByCourseId(UUID courseId);
    List<LiveSessionEntity> findByCourseIdIn(List<UUID> courseIds);
    List<LiveSessionEntity> findByInstructorEmail(String instructorEmail);
}
