package com.skillforge.course.repository;

import com.skillforge.course.entity.CourseEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CourseRepository extends JpaRepository<CourseEntity, UUID> {
    List<CourseEntity> findByCategorySlug(String categorySlug);
    List<CourseEntity> findByInstructorEmail(String instructorEmail);
}
