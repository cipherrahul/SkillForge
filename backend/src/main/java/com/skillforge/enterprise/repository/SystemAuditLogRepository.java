package com.skillforge.enterprise.repository;

import com.skillforge.enterprise.entity.SystemAuditLogEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SystemAuditLogRepository extends JpaRepository<SystemAuditLogEntity, UUID> {
    List<SystemAuditLogEntity> findBySeverity(String severity);
}
