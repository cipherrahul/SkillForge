package com.skillforge.course.repository;

import com.skillforge.course.entity.SectionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface SectionRepository extends JpaRepository<SectionEntity, UUID> {
}
