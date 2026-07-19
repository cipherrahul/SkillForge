package com.skillforge.community.repository;

import com.skillforge.community.entity.UserStatsEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserStatsRepository extends JpaRepository<UserStatsEntity, UUID> {
    Optional<UserStatsEntity> findByUserEmail(String userEmail);
    List<UserStatsEntity> findAllByOrderByXpPointsDesc();
}
