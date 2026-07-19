package com.skillforge.course.repository;

import com.skillforge.course.entity.ReviewEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReviewRepository extends JpaRepository<ReviewEntity, UUID> {
    List<ReviewEntity> findByCourseId(UUID courseId);
    Optional<ReviewEntity> findByCourseIdAndUserEmail(UUID courseId, String userEmail);
}
