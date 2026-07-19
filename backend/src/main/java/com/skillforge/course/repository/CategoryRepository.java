package com.skillforge.course.repository;

import com.skillforge.course.entity.CategoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<CategoryEntity, UUID> {
    Optional<CategoryEntity> findBySlug(String slug);
    boolean existsBySlug(String slug);
}
