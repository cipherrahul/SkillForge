package com.skillforge.course.repository;

import com.skillforge.course.entity.WishlistEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WishlistRepository extends JpaRepository<WishlistEntity, UUID> {
    List<WishlistEntity> findByUserEmail(String userEmail);
    Optional<WishlistEntity> findByUserEmailAndCourseId(String userEmail, UUID courseId);
    boolean existsByUserEmailAndCourseId(String userEmail, UUID courseId);
}
