package com.skillforge.ai.repository;

import com.skillforge.ai.entity.AiMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AiMessageRepository extends JpaRepository<AiMessageEntity, UUID> {
    List<AiMessageEntity> findBySessionIdOrderByTimestampAsc(UUID sessionId);
}
