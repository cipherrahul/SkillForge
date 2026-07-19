package com.skillforge.analytics.repository;

import com.skillforge.analytics.entity.UserActivityLogEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserActivityLogRepository extends JpaRepository<UserActivityLogEntity, UUID> {
    List<UserActivityLogEntity> findByUserEmail(String userEmail);
    List<UserActivityLogEntity> findByTimestampAfter(Instant timestamp);
}
