package com.skillforge.career.repository;

import com.skillforge.career.entity.ResumeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ResumeRepository extends JpaRepository<ResumeEntity, UUID> {
    Optional<ResumeEntity> findByUserEmail(String userEmail);
}
