package com.skillforge.ai.repository;

import com.skillforge.ai.entity.AiRoadmapEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AiRoadmapRepository extends JpaRepository<AiRoadmapEntity, UUID> {
    List<AiRoadmapEntity> findByUserEmail(String userEmail);
}
