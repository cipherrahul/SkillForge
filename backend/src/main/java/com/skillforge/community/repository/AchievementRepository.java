package com.skillforge.community.repository;

import com.skillforge.community.entity.AchievementEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AchievementRepository extends JpaRepository<AchievementEntity, UUID> {
    List<AchievementEntity> findByUserEmail(String userEmail);
    boolean existsByUserEmailAndTitle(String userEmail, String title);
}
