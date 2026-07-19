package com.skillforge.ai.repository;

import com.skillforge.ai.entity.AiSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AiSessionRepository extends JpaRepository<AiSessionEntity, UUID> {
}
