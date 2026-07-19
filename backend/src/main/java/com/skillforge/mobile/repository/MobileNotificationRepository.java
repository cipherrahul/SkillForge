package com.skillforge.mobile.repository;

import com.skillforge.mobile.entity.MobileNotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MobileNotificationRepository extends JpaRepository<MobileNotificationEntity, UUID> {
    List<MobileNotificationEntity> findByUserEmail(String userEmail);
}
