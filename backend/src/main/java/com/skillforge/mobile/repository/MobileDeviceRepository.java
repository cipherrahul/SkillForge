package com.skillforge.mobile.repository;

import com.skillforge.mobile.entity.MobileDeviceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MobileDeviceRepository extends JpaRepository<MobileDeviceEntity, UUID> {
    Optional<MobileDeviceEntity> findByDeviceToken(String deviceToken);
    List<MobileDeviceEntity> findByUserEmail(String userEmail);
}
